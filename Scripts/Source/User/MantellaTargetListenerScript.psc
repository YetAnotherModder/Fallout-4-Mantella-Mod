Scriptname MantellaTargetListenerScript extends ReferenceAlias
;new property added after Mantella 0.9.2
Import SUP_F4SE
MantellaRepository property repository auto
Keyword Property AmmoKeyword Auto Const
int CleanUpTimerID=1
Event Oninit()
    StartRegisteringEvents()
EndEvent

Function StartRegisteringEvents()
    ;adds AddInventoryEventFilter, necessary for OnItemAdded & OnItemRemoved to work properly
    RemoveAllInventoryEventFilters()
    AddInventoryEventFilter(none) 
    ;adds RegisterForHitEvent at load, necessary for Onhit to work properly
    ;UnregisterForAllHitEvents(self.GetActorReference())
    ;RegisterForHitEvent(self.GetActorReference())
    ;StartTimer(20,CleanUpTimerID)  
Endfunction

;Event Ontimer( int TimerID)  
;    if TimerID==CleanUpTimerID
;        debug.Notification("Stop registering events")
;        if repository.endFlagMantellaConversationOne == True
        ;Check periodically to cleanup any leftover filters and unregister for listeners
;        RemoveAllInventoryEventFilters()
;        UnregisterForAllHitEvents(self.GetActorReference())
;        else 
;            StartTimer(20,CleanUpTimerID)  
;        endif
;    endif
;EndEvent
;All the event listeners below have 'if' clauses added after Mantella 0.9.2 (except ondying)
Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    if Repository.targetTrackingItemAdded
        string sourceName = akSourceContainer.getbaseobject().getname()
        if sourceName != "Power Armor" ;to prevent gameevent spam from the NPCs entering power armors 
            String selfName = self.GetActorReference().getdisplayname()
            string itemName = akBaseItem.GetName()
            string itemPickedUpMessage = selfName+" picked up " + itemName + ".\n"
            if itemName == "Powered Armor Frame" 
                itemPickedUpMessage = selfName+" entered power armor.\n"
            else
                if sourceName != ""
                    itemPickedUpMessage = selfName+" picked up " + itemName + " from " + sourceName + ".\n"
                endIf
            Endif
            if itemName != "" 
                SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", itemPickedUpMessage, 2)
            endIf
        endif
    endif
EndEvent


Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
    if Repository.targetTrackingItemRemoved && !akBaseItem.HasKeyword(AmmoKeyword)
        string destName = akDestContainer.getbaseobject().getname()
        if destName != "Power Armor" ;to prevent gameevent spam from the NPC exiting power armors 
            String selfName = self.GetActorReference().getdisplayname()
            string itemName = akBaseItem.GetName()
            string itemDroppedMessage = selfName+" dropped " + itemName + ".\n"
            if itemName == "Powered Armor Frame" 
                itemDroppedMessage = selfName+" exited power armor.\n"
            else
                if destName != "" 
                    itemDroppedMessage = selfName+" placed " + itemName + " in/on " + destName + ".\n"
                endIf
            Endif
            SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", itemDroppedMessage, 2)
        endif
    endif
endEvent

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
        String selfName = self.GetActorReference().getdisplayname()
        debug.notification("Aggressor ref is"+akAggressor+" Self ref is "+self.GetActorReference())
        ; avoid writing events too often (continuous spells record very frequently)
        ; if the actor and weapon hasn't changed, only record the event every 5 hits
        if ((hitSource != lastHitSource) && (aggressor != lastAggressor)) || (timesHitSameAggressorSource > 5)
            lastHitSource = hitSource
            lastAggressor = aggressor
            timesHitSameAggressorSource = 0
            
            if (hitSource == "None") || (hitSource == "")
                ;Debug.MessageBox(aggressor + " punched "+selfName+".")
                SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", aggressor + " punched "+selfName+".\n", 2)
            elseif hitSource == "Mantella"
                ; Do not save event if Mantella itself is cast
            elseif akAggressor == self.GetActorReference()
                if self.GetActorReference().getleveledactorbase().getsex() == 0
                    SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", selfName+" hit himself with " + hitSource+".\n", 2)
                else
                    SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", selfName+" hit herself with " + hitSource+".\n", 2)
                endIf
            else
                ;Debug.MessageBox(aggressor + " hit "+selfName+" with a(n) " + hitSource)
                SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", aggressor + " hit "+selfName+" with " + hitSource+".\n", 2)
            endIf
        else
            timesHitSameAggressorSource += 1
        endIf
    endif
    ;reapply RegisterForHitEvent, necessary for Onhit to work properly
    RegisterForHitEvent(self.GetActorReference())
EndEvent


Event OnCombatStateChanged(Actor akTarget, int aeCombatState)
    if repository.targetTrackingOnCombatStateChanged
        String selfName = self.GetActorReference().getdisplayname()
        String targetName
        if akTarget == Game.GetPlayer()
            targetName = "the player"
        else
            targetName = akTarget.getdisplayname()
        endif

        if (aeCombatState == 0)
            ;Debug.MessageBox(selfName+" is no longer in combat")
            SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", selfName+" is no longer in combat.\n", 2)
        elseif (aeCombatState == 1)
            ;Debug.MessageBox(selfName+" has entered combat with "+targetName)
            SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", selfName+" has entered combat with "+targetName+".\n", 2)
        elseif (aeCombatState == 2)
            ;Debug.MessageBox(selfName+" is searching for "+targetName)
            SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", selfName+" is searching for "+targetName+".\n", 2)
        endIf
    endif
endEvent


Event OnItemEquipped(Form akBaseObject, ObjectReference akReference)
    if repository.targetTrackingOnObjectEquipped
        String selfName = self.GetActorReference().getdisplayname()
        string itemEquipped = akBaseObject.getname()
        ;Debug.MessageBox(selfName+" equipped " + itemEquipped)
        SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", selfName+" equipped " + itemEquipped + ".\n", 2)
    endif
endEvent


Event OnItemUnequipped(Form akBaseObject, ObjectReference akReference)
    if repository.targetTrackingOnObjectUnequipped
        String selfName = self.GetActorReference().getdisplayname()
        string itemUnequipped = akBaseObject.getname()
        ;Debug.MessageBox(selfName+" unequipped " + itemUnequipped)
        SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", selfName+" unequipped " + itemUnequipped + ".\n", 2)
    endif
endEvent

Event OnSit(ObjectReference akFurniture)
    if repository.targetTrackingOnSit
        String selfName = self.GetActorReference().getdisplayname()
        ;Debug.MessageBox(selfName+" sat down.")
        String furnitureName = akFurniture.getbaseobject().getname()
        ; only save event if actor is sitting / resting on furniture (and not just, for example, leaning on a bar table)
        if furnitureName != ""
            SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", selfName+" sat down / rested on a(n) "+furnitureName+".\n", 2)
        endIf
    endif
endEvent


Event OnGetUp(ObjectReference akFurniture)
    if  repository.targetTrackingOnGetUp
        String selfName = self.GetActorReference().getdisplayname()
        ;Debug.MessageBox(selfName+" stood up.")
        String furnitureName = akFurniture.getbaseobject().getname()
        ; only save event if actor is sitting / resting on furniture (and not just, for example, leaning on a bar table)
        if furnitureName != ""
            SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", selfName+" stood up from a(n) "+furnitureName+".\n", 2)
        endIf
    endif
EndEvent


Event OnDying(Actor akKiller)
    SUP_F4SE.WriteStringToFile("_mantella_end_conversation.txt", "True", 0)
EndEvent

Event OnCommandModeGiveCommand(int aeCommandType, ObjectReference akTarget)
    if repository.targetTrackingGiveCommands && aeCommandType!=0
        string commandMessage=""
        string selfName=self.GetActorReference().getdisplayname()
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
            commandMessage=" was asked to move to the designated spot ("+akTarget.GetDisplayName()+") at the player's request"
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
        commandMessage=(selfName+commandMessage+".\n")
        ;debug.notification(commandMessage)
        if validrequest
            SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", commandMessage, 2)
        endif
    endif
endEvent


Event OnCommandModeCompleteCommand(int aeCommandType, ObjectReference akTarget)
    ;debug.notification("Completed command"+aeCommandType)
    if repository.targetTrackingCompleteCommands && aeCommandType!=0
        string commandMessage=""
        string selfName=self.GetActorReference().getdisplayname()
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
        SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", selfName+commandMessage+".\n", 2)
    endif
EndEvent
