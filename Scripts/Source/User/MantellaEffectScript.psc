Scriptname MantellaEffectScript extends activemagiceffect
Import SUP_F4SE

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


;####################################################
;#                    Legacy Code                    #
;####################################################

; event OnEffectStart(Actor target, Actor caster) 
;     bool proceedWithConversation = true 
;     bool casterIsPlayer=false
;     String actorCountString = SUP_F4SE.ReadStringFromFile("_mantella_actor_count.txt",0,1) 
;     int actorCount = actorCountString as int

;     ;checks if the player is attempting to start a conversation and offer them to choose to add a new NPC or not
;     if caster == playerRef && actorCount>0
;         casterIsPlayer=true
;         int aButton=MantellaStartConversationMessage.show()
;         if aButton==1 ;player chose no
;             ;cleanupprevious Onhit event listeners
;             ;UnregisterForAllHitEvents(TargetRefAlias)
;             ;actorCount=0
;             ;SUP_F4SE.WriteStringToFile("activeActors.txt", "", 0)
;             ;StopConversations()
;             proceedWithConversation=false
;         elseif aButton==0 ;player chose yes
;             debug.notification("Adding NPC to conversation")
;         endif 
;     ElseIf caster == playerRef && actorCount==0
;         ;cleanupprevious Onhit event listeners
;         UnregisterForAllHitEvents(TargetRefAlias)
;         casterIsPlayer=true
;         actorCount=0
;         SUP_F4SE.WriteStringToFile("activeActors.txt", "", 0)
;         StopConversations()
;     endif
;     if proceedWithConversation==true
;         String playerRace = PlayerRef.GetRace().GetName()
;         Int playerGenderID = PlayerRef.GetActorBase().GetSex()
;         String playerGender = ""
;         if (playerGenderID == 0)
;             playerGender = "Male"
;         else
;             playerGender = "Female"
;         endIf
;         String playerName = PlayerRef.GetActorBase().GetName()
;         SUP_F4SE.WriteStringToFile("_mantella_player_name.txt", playerName, 0)
;         SUP_F4SE.WriteStringToFile("_mantella_player_race.txt", playerRace, 0)
;         SUP_F4SE.WriteStringToFile("_mantella_player_gender.txt", playerGender, 0)

;         String character_selection_enabled = SUP_F4SE.ReadStringFromFile("_mantella_character_selection.txt",0,1) 
;         String activeActors = SUP_F4SE.ReadStringFromFile("_mantella_active_actors.txt",0,10)
;         string actorName = target.GetDisplayName()
;         String casterName = caster.getdisplayname()


;         ;if radiant dialogue between two NPCs, label them 1 & 2
;         if (casterName == actorName)
;             if actorCount == 0
;                 actorName = actorName + " 1"
;                 casterName = casterName + " 2"
;             elseIf actorCount == 1
;                 actorName = actorName + " 2"
;                 casterName = casterName + " 1"
;             endIf
;         endIf

;         int index = SUP_F4SE.SUPStringFind(activeActors, actorName,0,0)
;         bool actorAlreadyLoaded = true
;         if index == -1
;             actorAlreadyLoaded = false
;         endIf

;         String radiantDialogue = SUP_F4SE.ReadStringFromFile("_mantella_radiant_dialogue.txt",0,2)
;         ; if radiant dialogue is active without the actor selected by player, end the radiant dialogue
;         if (radiantDialogue == "True") && (caster == Game.GetPlayer()) && (actorAlreadyLoaded == false)
;             Debug.Notification("Ending radiant dialogue")
;             SUP_F4SE.WriteStringToFile("_mantella_end_conversation.txt", "True", 0)
;         ; if selected actor is in radiant dialogue, disable this mode to allow the player to join the conversation
;         elseIf (radiantDialogue == "True") && (actorAlreadyLoaded == true) && (caster == Game.GetPlayer())
;             Debug.Notification("Adding player to conversation")
;             SUP_F4SE.WriteStringToFile("_mantella_radiant_dialogue.txt", "False", 0)
;         ; if actor not already loaded and character selection is enabled
;         elseif (actorAlreadyLoaded == false) && (character_selection_enabled == "True")
;             TargetRefAlias.ForceRefTo(target)      
;             RegisterForHitEvent(TargetRefAlias.GetTargetActor())
;             String actorId = (target.getactorbase() as form).getformid()
;             String actorRefId = target.getformid() 
;             ;debug.notification("Actor ID is "+actorId)
;             ;MiscUtil.WriteToFile("_mantella_current_actor_id.txt", actorId, append=false) THIS IS HOW THE FUNCTION LOOKS IN SKYRIM
;             ;SUP_F4SE.WriteStringToFile(string sFilePath,string sText, int iAppend [0 for clean file, 1 for append, 2 for append with new line])
;             SUP_F4SE.WriteStringToFile("_mantella_current_actor_id.txt",actorId, 0)
;             SUP_F4SE.WriteStringToFile("_mantella_current_actor_ref_id.txt",actorRefId, 0)
;             SUP_F4SE.WriteStringToFile("_mantella_current_actor.txt",actorName, 0)
;             ;this will eventually be rewritten when multi-NPC conversation is implemented in FO4
;             SUP_F4SE.WriteStringToFile("_mantella_active_actors.txt"," "+actorName+" ", 1)
;             ;debug.messagebox("Current active actors "+SUP_F4SE.ReadStringFromFile("_mantella_active_actors.txt",0,10))
;             SUP_F4SE.WriteStringToFile("_mantella_character_selection.txt","false",0)

;             String actorSex = target.getleveledactorbase().getsex()
;             SUP_F4SE.WriteStringToFile("_mantella_actor_sex.txt", actorSex, 0)

;             String actorRace = target.getrace()
;             SUP_F4SE.WriteStringToFile("_mantella_actor_race.txt", actorRace, 0)

;             String actorRelationship = target.getrelationshiprank(PlayerRef)
;             SUP_F4SE.WriteStringToFile("_mantella_actor_relationship.txt", actorRelationship, 0)

;             String actorVoiceType = target.GetVoiceType()
;             SUP_F4SE.WriteStringToFile("_mantella_actor_voice.txt", actorVoiceType, 0)
;             ;the below is to build a substring to use later to find the correct wav file 
;             String isEnemy = "False"
;             if (target.getcombattarget() == PlayerRef)
;                 isEnemy = "True"
;             endIf
;             SUP_F4SE.WriteStringToFile("_mantella_actor_is_enemy.txt", isEnemy, 0)

;             String currLoc = (caster.GetCurrentLocation() as form).getname()
;             if currLoc == ""
;                 currLoc = "Boston area"
;             endIf
;             SUP_F4SE.WriteStringToFile("_mantella_current_location.txt", currLoc, 0)

;             int Time = GetCurrentHourOfDay()
;             SUP_F4SE.WriteStringToFile("_mantella_in_game_time.txt", Time, 0)

;             ;will eventually be modified when multi-NPC conversation are added to FO4
;             actorCount += 1
;             SUP_F4SE.WriteStringToFile("_mantella_actor_count.txt", actorCount, 0)

;             if actorCount == 1 ; reset player input if this is the first actor selected
;                 SUP_F4SE.WriteStringToFile("_mantella_text_input_enabled.txt", "False", 0)
;                 SUP_F4SE.WriteStringToFile("_mantella_text_input.txt", "", 0)
;                 SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", "", 0)
;             endif
            
            
;             if casterIsPlayer && actorCount>1
;                 Debug.Notification("Adding " + actorName+" to the conversation.")
;             elseif casterIsPlayer
;                     Debug.Notification("Starting conversation with " + actorName)
;             elseIf actorCount == 1
;                 Debug.Notification("Starting radiant dialogue with " + actorName + " and " + casterName)
;             endIf

            
;             repository.endFlagMantellaConversationOne = false
;             bool endConversation = false
;             string sayFinalLine
;             String sayLineFile = "_mantella_say_line_"+actorCount+".txt"
;             int loopCount

;             ; Wait for first voiceline to play to avoid old conversation playing
;             Utility.Wait(0.5)

;             SUP_F4SE.WriteStringToFile("_mantella_character_selected.txt", "True", 0)
;             while repository.endFlagMantellaConversationOne == false && endConversation == false
;                 if actorCount == 1
;                     MainConversationLoop( target, caster, loopCount, actorName, actorRelationship)
;                     loopCount+=1
;                 Else
;                     ConversationLoop(target, caster, actorName, sayLineFile)
;                 endif


;                 if sayFinalLine == "True"
;                     endConversation = True
;                     localMenuTimer = -1
;                 endIf
;                 sayFinalLine = SUP_F4SE.ReadStringFromFile("_mantella_end_conversation.txt",0, 2) 
;             endWhile
;             debug.notification("Conversation with "+actorName+" has ended")
;         Else
;             Debug.Notification("NPC not added. Please try again after your next response.")    
;         endif
;     endif
;     ;cleanup magicactiveeffect
;     self.Dispel()
;     ;cleanup Onhit event listener
;     UnregisterForAllHitEvents(target)

; endevent

; function MainConversationLoop(Actor target, Actor caster, int loopCount, String actorName, String actorRelationship)
;         String sayLine = SUP_F4SE.ReadStringFromFile("_mantella_say_line.txt",0,99) 

;         if sayLine != "False" && !SUP_F4SE.IsMenuModeActive()
;             target.SetLookAt(caster, false)
;             Utility.wait (0.1)
;             ;This function is there to activate the lip file, the audio for MantellaDialogue line is actually 10 seconds of silence.
;             target.Say(MantellaDialogueLine, abSpeakInPlayersHead=false)
;             ;###the function  internalMantellaAudioPlay is deprecated with F4SE 11.60   ###
;             ;internalMantellaAudioPlay(sayline, target) 
;             externalMantellaAudioPlay(sayline, target)
;             SUP_F4SE.WriteStringToFile("_mantella_say_line.txt", "False", 0)
;             localMenuTimer = -1
           
;             ; Check aggro status after every line spoken
;             if repository.allowAggro || repository.allowFollow
;                 String aggro = SUP_F4SE.ReadStringFromFile("_mantella_aggro.txt",0,2)
;                 if repository.allowAggro
;                     if aggro == "0"
;                         Debug.Notification(actorName + " forgave you.")
;                         target.StopCombat()
;                         SUP_F4SE.WriteStringToFile("_mantella_aggro.txt", "",  0)
;                     elseIf aggro == "1"
;                         Debug.Notification(actorName + " did not like that.")
;                         target.StartCombat(caster)
;                         SUP_F4SE.WriteStringToFile("_mantella_aggro.txt", "",  0)
;                     endif
;                 endif
;                 if repository.allowFollow
;                     if aggro == "2"
;                         Debug.Notification(actorName + " is willing to follow you.")
;                         target.SetPlayerTeammate(true, true)
;                         SUP_F4SE.WriteStringToFile("_mantella_aggro.txt", "",  0)
;                     endIf
;                 endif
;             endif
;         endif
            

;         if loopCount % 5 == 0
;             ;move Time tracking to this section for it to run less frequently
;             int Time = GetCurrentHourOfDay()
;             SUP_F4SE.WriteStringToFile("_mantella_in_game_time.txt", Time, 0)

;             String status = SUP_F4SE.ReadStringFromFile("_mantella_status.txt",0,99) 
;             if status != "False"
;                 Debug.Notification(status)
;                 SUP_F4SE.WriteStringToFile("_mantella_status.txt", "False", 0)
;                 if status == "Listening..."
;                     repository.writePlayerState()
;                 endif
;             endIf
            
;             ;text input to implement later
;             String playerResponse = SUP_F4SE.ReadStringFromFile ("_mantella_text_input_enabled.txt",0,2) 
;             if playerResponse == "True"
;                 StartTextTimer()
;             endIf
;         endIf

;         if loopCount % 20 == 0
;             String radiantDialogue = SUP_F4SE.ReadStringFromFile("_mantella_radiant_dialogue.txt",0,2) 
;             if radiantDialogue == "True"
;                 float distanceBetweenActors = caster.GetDistance(target)
;                 float distanceToPlayer = ConvertGameUnitsToMeter(caster.GetDistance(PlayerRef))
;                 ;Debug.Notification(distanceBetweenActors)
;                 ;TODO: allow distanceBetweenActos limit to be customisable
;                 if (distanceBetweenActors > 1500) || (distanceToPlayer > repository.radiantDistance) || (caster.GetCurrentLocation() != target.GetCurrentLocation()) || (caster.GetCurrentScene() != None) || (target.GetCurrentScene() != None)
;                     Debug.messagebox("Conversation ended, possibly because of distance "+distanceBetweenActors)
;                     SUP_F4SE.WriteStringToFile("_mantella_end_conversation.txt", "True", 0)
;                 endIf
;             endIf
;         endIf
; endfunction

; function externalMantellaAudioPlay(string sayline, actor target)
;     ;Get the player's and target position to determine audio direction
;     float game_angle_z = PlayerRef.GetAngleZ()
;     float playerpositionX=playerref.getpositionX()
;     float playerpositionY=playerref.getpositionY()
;     float targetpositionX=target.getpositionX()
;     float targetpositionY=target.getpositionY()
;     float currentDistance=target.GetDistance(playerref)
;     string audio_array = currentDistance as string+","+playerpositionX+","+playerpositionY+","+game_angle_z +","+targetpositionX+","+targetpositionY
;     SUP_F4SE.WriteStringToFile("_mantella_audio_ready.txt", audio_array, 0)
;     if repository.notificationsSubtitlesEnabled
;         debug.notification(target.GetDisplayName()+":"+sayline)
;     endif
;     string checkAudioDistance = currentDistance as string
;     ;Start a loop waiting to hear back from Python
;     debug.trace("Starting while loop waiting for audio to finish playing")
;     While checkAudioDistance != "false" && repository.endFlagMantellaConversationOne == false
;         checkAudioDistance= SUP_F4SE.ReadStringFromFile("_mantella_audio_ready.txt",0,99)
;     endwhile
;     repository.ResetEventSpamBlockers() ;this allows eventlistener to become active again
; endfunction

; function ConversationLoop(Actor target, Actor caster, String actorName, String sayLineFile)
;     String sayLine = SUP_F4SE.ReadStringFromFile(sayLineFile,0,99)
;     if sayLine != "False"
;         target.SetLookAt(caster, false)
;         Utility.wait (0.1)
;         ;This function is there to activate the lip file, the audio for MantellaDialogue line is actually 10 seconds of silence.
;         target.Say(MantellaDialogueLine, abSpeakInPlayersHead=false)
;         ;###the function  internalMantellaAudioPlay is deprecated with F4SE 11.60   ###
;         ;internalMantellaAudioPlay(sayline, target) 
;         externalMantellaAudioPlay(sayline, target)
;         ; Set sayLine back to False once the voiceline has been triggered
;         SUP_F4SE.WriteStringToFile(sayLineFile, "False", 0)
;         localMenuTimer = -1
;     endIf
; endFunction

; function StartTextTimer()
; 	localMenuTimer=180
;     int localMenuTimerInt = Math.Floor(localMenuTimer)
; 	Debug.Notification("Awaiting player input for "+localMenuTimerInt+" seconds")
; 	String Monitorplayerresponse
; 	String timerCheckEndConversation
; 	;Debug.Notification("Timer is "+localMenuTimer)
; 	While localMenuTimer >= 0 && repository.endFlagMantellaConversationOne==false
; 		;Debug.Notification("Timer is "+localMenuTimer)
; 		Monitorplayerresponse = SUP_F4SE.ReadStringFromFile("_mantella_text_input_enabled.txt",0,2) 
; 		timerCheckEndConversation = SUP_F4SE.ReadStringFromFile("_mantella_end_conversation.txt",0,2) 
; 		;the next if clause checks if another conversation is already running and ends it.
; 		if timerCheckEndConversation == "true" ;|| repository.endFlagMantellaConversationOne==true (MAYBE ADD THIS BACK?)
; 			localMenuTimer = -1
;             SUP_F4SE.WriteStringToFile("_mantella_say_line.txt", "False", 0)
; 			return
; 		endif
; 		if Monitorplayerresponse == "False"
; 			localMenuTimer = -1
; 		endif
; 		If localMenuTimer > 0
; 			Utility.Wait(1)
; 			if !SUP_F4SE.IsMenuModeActive()
; 				localMenuTimer = localMenuTimer - 1
; 			endif
; 			;Debug.Notification("Timer is "+localMenuTimer)
; 		elseif localMenuTimer == 0
; 			Monitorplayerresponse = "False"
; 			;added this as a safety check in case the player stays in a menu a long time.
;             Monitorplayerresponse = SUP_F4SE.ReadStringFromFile("_mantella_text_input_enabled.txt",0,2)
; 			if Monitorplayerresponse == "True"
; 				;Debug.Notification("opening menu now")
; 				repository.OpenTextMenu()
;                 if repository.textinput != ""
;                     SUP_F4SE.WriteStringToFile("_mantella_text_input_enabled.txt", "False", 0)
;                     SUP_F4SE.WriteStringToFile("_mantella_text_input.txt", repository.textinput, 0)
;                 endIf
; 			endIf
; 			localMenuTimer = -1
; 		endIf
; 	endWhile
; endFunction

; int function GetCurrentHourOfDay()
; 	float Time = Utility.GetCurrentGameTime()
; 	Time -= Math.Floor(Time) ; Remove "previous in-game days passed" bit
; 	Time *= 24 ; Convert from fraction of a day to number of hours
; 	int Hour = Math.Floor(Time) ; Get whole hour
; 	return Hour
; endFunction


; Float Function ConvertMeterToGameUnits(Float meter)
;     Return Meter * meterUnits
; EndFunction

; Float Function ConvertGameUnitsToMeter(Float gameUnits)
;     Return gameUnits / meterUnits
; EndFunction

; String lastHitSource = ""
; String lastAggressor = ""
; Int timesHitSameAggressorSource = 0
; Event OnHit(ObjectReference akTarget, ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked, string apMaterial)
;     if repository.targetTrackingOnHit 
;         String aggressor
;         if akAggressor == Game.GetPlayer()
;             aggressor = "The player"
;         else
;             aggressor = akAggressor.getdisplayname()
;         endif
;         string hitSource = akSource.getname()
;         String selfName = TargetRefAlias.GetTargetActor().getdisplayname()
;         ; avoid writing events too often (continuous spells record very frequently)
;         ; if the actor and weapon hasn't changed, only record the event every 5 hits
;         if ((hitSource != lastHitSource) && (aggressor != lastAggressor)) || (timesHitSameAggressorSource > 5)
;             lastHitSource = hitSource
;             lastAggressor = aggressor
;             timesHitSameAggressorSource = 0
            
;             if (hitSource == "None") || (hitSource == "")
;                 ;Debug.MessageBox(aggressor + " punched "+selfName+".")
;                 SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", aggressor + " punched "+selfName+".\n", 2)
;             elseif hitSource == "Mantella"
;                 ; Do not save event if Mantella itself is cast
;             elseif akAggressor == TargetRefAlias.GetTargetActor()
;                 if TargetRefAlias.GetTargetActor().getleveledactorbase().getsex() == 0
;                     SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", selfName+" hit himself with " + hitSource+".\n", 2)
;                 else
;                     SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", selfName+" hit herself with " + hitSource+".\n", 2)
;                 endIf
;             else
;                 ;Debug.MessageBox(aggressor + " hit "+selfName+" with a(n) " + hitSource)
;                 SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", aggressor + " hit "+selfName+" with " + hitSource+".\n", 2)
;             endIf
;         else
;             timesHitSameAggressorSource += 1
;         endIf
;     endif
;     ;reapply RegisterForHitEvent, necessary for Onhit to work properly
;     RegisterForHitEvent(TargetRefAlias.GetTargetActor())
; EndEvent

; Function StopConversations()
;     debug.notification("Cleaning up before starting conversation")
;     repository.endFlagMantellaConversationOne = True
;     Utility.Wait(0.5)
;     repository.endFlagMantellaConversationOne = False
; EndFunction

