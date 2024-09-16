Scriptname MantellaEffectScript extends activemagiceffect
;Import SUP_F4SE

Topic property MantellaDialogueLine auto
GlobalVariable property MantellaWaitTimeBuffer auto
MantellaRepository property repository auto
MantellaConversation property conversation auto
float localMenuTimer
Float meterUnits = 78.74
Actor property PlayerRef auto
Message property MantellaStartConversationMessage auto
Message property MantellaActorIsInConvoMessage auto
Keyword Property AmmoKeyword Auto Const

;##############################################################
;#            Magic Effect Start and finish Event managers    #
;##############################################################


event OnEffectStart(Actor target, Actor caster)
    ;RegisterForModEvent("SKSE_HTTP_OnHttpReplyReceived","OnHttpReplyReceived")
    ;Utility.Wait(0.5)
    Actor[] actors = new Actor[2]
    actors[0] = caster
    actors[1] = target
    if(!conversation.IsRunning())
        if  caster == playerRef 
            Debug.Notification("Starting conversation with "+target.getdisplayname())
        Else
            Debug.Notification(caster.GetDisplayName() + " is talking to " + target.GetDisplayName())
        endif
        ;Need to test these and move on their own function
        ActivateEventsFilters()
        repository.ResetEventSpamBlockers() ;reset spam blockers to allow the Listener Script to pick up on those again
        repository.hasPendingVisionCheck=false
        conversation.Start()
        conversation.StartConversation(actors)
    elseif conversation.conversationIsEnding ==true
        debug.notification("Conversation is currently ending,try again in a few seconds")
        self.dispel() ;remove the Mantella effect form the actor so they don't show up in the event listeners
    elseif conversation.IsActorInConversation(target)
        showAndResolveActorIsInConvoMessage(target)
    Elseif caster == playerRef  ;initiates a menu check
        showAndResolveAddtoConversationMessage(target) 
    else ;will be used when radiant conversation are started
        conversation.AddActorsToConversation(actors)
    endIf
endEvent

;will activate on dispel()
Event OnEffectFinish(Actor target, Actor caster)
    ;debug.notification("Mantella has ended on "+target.getdisplayname())
    DeactivateEventsFilters()
endEvent

;####################################################
;#         Message Handling Functions               #
;####################################################

function showAndResolveAddtoConversationMessage(Actor target)
    int aButton=MantellaStartConversationMessage.show()
    if aButton==1 ;player chose no
         self.dispel() ;remove the Mantella effect form the actor so they don't show up in the event listeners
    elseif aButton==0 ;player chose yes
        debug.notification("Adding "+target.getdisplayname()+" to conversation")
        ActivateEventsFilters()
        Actor[] actorsToAdd = new Actor[1]
        actorsToAdd[0] = target
        conversation.AddActorsToConversation(actorsToAdd)
    endif 
Endfunction

function showAndResolveActorIsInConvoMessage(Actor target)
    int aButton=MantellaActorIsInConvoMessage.show()
    if aButton==1 ;player chose no
         ;do nothing
    elseif aButton==0 ;player chose yes
        debug.notification("Removing "+target.getdisplayname()+" from the conversation")
        ;Need to test these and move on their own function
        self.dispel() ;remove the Mantella effect form the actor so they don't show up in the event listeners
        Actor[] actorsToRemove = new Actor[1]
        actorsToRemove[0] = target
        conversation.RemoveActorsFromConversation(actorsToRemove)
    endif 
Endfunction

;####################################################
;#                  Game Event filter Functions    #
;####################################################

Function ActivateEventsFilters()
    RemoveAllInventoryEventFilters()
    UnregisterForAllHitEvents(GetTargetActor())
    AddInventoryEventFilter(none) 
    RegisterForHitEvent(GetTargetActor())
EndFunction

Function DeactivateEventsFilters()
    RemoveAllInventoryEventFilters()
    UnregisterForAllHitEvents(GetTargetActor())
EndFunction


;####################################################
;#              Game events Listeners               #
;####################################################

;test
Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    if Repository.targetTrackingItemAdded
        string sourceName = akSourceContainer.getbaseobject().getname()
        if sourceName != "Power Armor" ;to prevent gameevent spam from the NPCs entering power armors 
            String selfName = self.GetTargetActor().getdisplayname()
            string itemName = akBaseItem.GetName()
            string itemPickedUpMessage = selfName+" picked up " + itemName
            if itemName == "Powered Armor Frame" 
                itemPickedUpMessage = selfName+" entered power armor."
            else
                if sourceName != ""
                    itemPickedUpMessage = selfName+" picked up " + itemName + " from " + sourceName
                endIf
            Endif
            if itemName != ""
                conversation.AddIngameEvent(itemPickedUpMessage) 
                ;debug.notification(itemPickedUpMessage)
            endIf
        endif
    endif
EndEvent


Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
    if Repository.targetTrackingItemRemoved
        string destName = akDestContainer.getbaseobject().getname()
        if destName != "Power Armor" ;to prevent gameevent spam from the NPC exiting power armors 
            String selfName = self.GetTargetActor().getdisplayname()
            string itemName = akBaseItem.GetName()
            string itemDroppedMessage = selfName+" dropped " + itemName
            if itemName == "Powered Armor Frame" 
                itemDroppedMessage = selfName+" exited power armor."
            else
                if destName != "" 
                    itemDroppedMessage = selfName+" placed " + itemName + " in/on " + destName
                    conversation.AddIngameEvent(itemDroppedMessage) 
                elseif akBaseItem.HasKeyword(AmmoKeyword)
                    ;filtering out ammo from item remove to prevent spam and confusion when a weapon is fired
                else
                    conversation.AddIngameEvent(itemDroppedMessage) 
                endIf
            Endif
        endif
    endif
endEvent


Event OnCombatStateChanged(Actor akTarget, int aeCombatState)
    if repository.targetTrackingOnCombatStateChanged
        String selfName = self.GetTargetActor().getdisplayname()
        String targetName
        if akTarget == Game.GetPlayer()
            targetName = "the player"
        else
            targetName = akTarget.getdisplayname()
        endif

        if (aeCombatState == 0)
            ;Debug.MessageBox(selfName+" is no longer in combat")
            conversation.AddIngameEvent(selfName+" is no longer in combat.") 
        elseif (aeCombatState == 1)
            ;Debug.MessageBox(selfName+" has entered combat with "+targetName)
            conversation.AddIngameEvent(selfName+" has entered combat with "+targetName) 
        elseif (aeCombatState == 2)
            ;Debug.MessageBox(selfName+" is searching for "+targetName)
            conversation.AddIngameEvent(selfName+" is searching for "+targetName) 
        endIf
    endif
endEvent


Event OnItemEquipped(Form akBaseObject, ObjectReference akReference)
    if repository.targetTrackingOnObjectEquipped
        String selfName = self.GetTargetActor().getdisplayname()
        string itemEquipped = akBaseObject.getname()
        ;Debug.MessageBox(selfName+" equipped " + itemEquipped)
        conversation.AddIngameEvent(selfName+" equipped " + itemEquipped) 
    endif
endEvent


Event OnItemUnequipped(Form akBaseObject, ObjectReference akReference)
    if repository.targetTrackingOnObjectUnequipped
        String selfName = self.GetTargetActor().getdisplayname()
        string itemUnequipped = akBaseObject.getname()
        ;Debug.MessageBox(selfName+" unequipped " + itemUnequipped)
        conversation.AddIngameEvent(selfName+" unequipped " + itemUnequipped) 
    endif
endEvent

Event OnSit(ObjectReference akFurniture)
    if repository.targetTrackingOnSit
        String selfName = self.GetTargetActor().getdisplayname()
        ;Debug.MessageBox(selfName+" sat down.")
        String furnitureName = akFurniture.getbaseobject().getname()
        ; only save event if actor is sitting / resting on furniture (and not just, for example, leaning on a bar table)
        if furnitureName != ""
            conversation.AddIngameEvent(selfName+" interacted with "+furnitureName) 
        endIf
    endif
endEvent

Event OnGetUp(ObjectReference akFurniture)
    if  repository.targetTrackingOnGetUp
        String selfName = self.GetTargetActor().getdisplayname()
        ;Debug.MessageBox(selfName+" stood up.")
        String furnitureName = akFurniture.getbaseobject().getname()
        ; only save event if actor is sitting / resting on furniture (and not just, for example, leaning on a bar table)
        if furnitureName != ""
            conversation.AddIngameEvent(selfName+" stopped interacting with "+furnitureName) 
        endIf
    endif
EndEvent

Event OnDying(Actor akKiller)
    If (conversation.IsRunning())
        conversation.EndConversation()
    EndIf
EndEvent

Event OnCommandModeGiveCommand(int aeCommandType, ObjectReference akTarget)
    if repository.targetTrackingGiveCommands && aeCommandType!=0
        string commandMessage=""
        string selfName=self.GetTargetActor().getdisplayname()
        bool validrequest=true
        if aeCommandType==1 ;Call - probably want to cut this one if it's too generic
            commandMessage=" was called by the player"
        elseif aeCommandType==2 ;Follow - 
            Int playerGenderID = game.GetPlayer().GetActorBase().GetSex()
            String playerPossessivePronoun="his"
            if (playerGenderID == 1)
                playerPossessivePronoun = "her"
            endIf
            commandMessage=" is following the player at "+playerPossessivePronoun+" request."
        elseif aeCommandType==3 ;Move - probably want to cut this one if it's too generic
            commandMessage=" was asked to move to the designated spot "+akTarget.GetDisplayName()+" at the player's request"
        elseif aeCommandType==4 ;Attack
            commandMessage=" attacked "+akTarget.GetDisplayName()+" at the player's request"
        elseif aeCommandType==5 ;Inspect
            commandMessage=" was asked to interact with "+akTarget.GetDisplayName()+" at the player's request"
        elseif aeCommandType==6 ;Retrieve
            if akTarget.GetDisplayName()!=""
                commandMessage=" is retrieving "+akTarget.GetDisplayName()+" at the player's request"
            Else
                validrequest=false
            endif
        elseif aeCommandType==7 ;Stay
            commandMessage=" was requested to stay in place by the player"
        elseif aeCommandType==8 ;Release - probably want to cut this one if it's too generic
            commandMessage=" was released from following orders by the player" 
        elseif aeCommandType==9 ;Heal 
            commandMessage=" healed "+akTarget.GetDisplayName()+" at the player's request"
        elseif aeCommandType==10 ;workshop assign 
            commandMessage=" was asked to take of the "+akTarget.GetDisplayName()+" in the settlement at the player's request"
        elseif aeCommandType==11 ;enter vertibird
            commandMessage=" was asked to enter the vehicle "+akTarget.GetDisplayName()+" at the player's request"
        elseif aeCommandType==12 ;enter power armor 
            commandMessage=" was aked to enter "+akTarget.GetDisplayName()+" at the player's request"
        endif
        commandMessage=(selfName+commandMessage)
        ;debug.notification(commandMessage)
        if validrequest
            conversation.AddIngameEvent(commandMessage) 
        endif
    endif
endEvent


Event OnCommandModeCompleteCommand(int aeCommandType, ObjectReference akTarget)
    ;debug.notification("Completed command"+aeCommandType)
    if repository.targetTrackingCompleteCommands && aeCommandType!=0
        string commandMessage=""
        string selfName=self.GetTargetActor().getdisplayname()
        if aeCommandType==1 ;Call - probably want to cut this one if it's too generic
            commandMessage=" was called by the player"
        elseif aeCommandType==2 ;Follow - 
            Int playerGenderID = game.GetPlayer().GetActorBase().GetSex()
            String playerPossessivePronoun="his"
            if (playerGenderID == 1)
                playerPossessivePronoun = "her"
            endIf
            commandMessage=" is following the player at "+playerPossessivePronoun+" request."
        elseif aeCommandType==3 ;Move - probably want to cut this one if it's too generic
            commandMessage=" moved to the designated spot ("+akTarget.GetDisplayName()+") at the player's request"
        elseif aeCommandType==4 ;Attack
            commandMessage=" attacked "+akTarget.GetDisplayName()+" at the player's request"
        elseif aeCommandType==5 ;Inspect
            commandMessage=" interacted with "+akTarget.GetDisplayName()+" at the player's request"
        elseif aeCommandType==6 ;Retrieve
            commandMessage=" retrieved items at the player's request"
        elseif aeCommandType==7 ;Stay
            commandMessage=" was requested to stay in place by the player"
        elseif aeCommandType==8 ;Release - probably want to cut this one if it's too generic
            commandMessage=" was released from following orders by the player" 
        elseif aeCommandType==9 ;Heal 
            commandMessage=" healed "+akTarget.GetDisplayName()+" at the player's request"
        endif
        conversation.AddIngameEvent(selfName+commandMessage) 
    endif
EndEvent

String lastHitSource = ""
String lastAggressor = ""
Int timesHitSameAggressorSource = 0
Event OnHit(ObjectReference akTarget, ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked, string apMaterial)
    if repository.targetTrackingOnHit 
         String aggressor
         if akAggressor == Game.GetPlayer()
             aggressor = "The player"
         else
             aggressor = akAggressor.getdisplayname()
         endif
         string hitSource = akSource.getname()
         String selfName = self.GetTargetActor().getdisplayname()
         ; avoid writing events too often (continuous spells record very frequently)
         ; if the actor and weapon hasn't changed, only record the event every 5 hits
         if ((hitSource != lastHitSource) && (aggressor != lastAggressor)) || (timesHitSameAggressorSource > 5)
             lastHitSource = hitSource
             lastAggressor = aggressor
             timesHitSameAggressorSource = 0
            
            if (hitSource == "None") || (hitSource == "")
                 ;Debug.MessageBox(aggressor + " punched "+selfName+".")
                 string eventMessage = aggressor + " damaged "+selfName+".\n"
                 conversation.AddIngameEvent(eventMessage) 
            elseif hitSource == "Mantella"
                 ; Do not save event if Mantella itself is used
            elseif akAggressor == self.GetTargetActor()
                if self.GetTargetActor().getleveledactorbase().getsex() == 0
                    string eventMessage = selfName+" hit himself with " + hitSource+".\n"
                    conversation.AddIngameEvent(eventMessage) 
                else
                    string eventMessage = selfName+" hit herself with " + hitSource+".\n"
                    conversation.AddIngameEvent(eventMessage) 
                endIf
            else
                 ;Debug.MessageBox(aggressor + " hit "+selfName+" with a(n) " + hitSource)
                 string eventMessage = aggressor + " hit "+selfName+" with " + hitSource+".\n"
                 conversation.AddIngameEvent(eventMessage) 
            endIf
        else
             timesHitSameAggressorSource += 1
        endIf
     endif
     ;reapply RegisterForHitEvent, necessary for Onhit to work properly
     RegisterForHitEvent(self.GetTargetActor())
 EndEvent

