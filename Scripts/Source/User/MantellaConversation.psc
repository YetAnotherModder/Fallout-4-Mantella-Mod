Scriptname MantellaConversation extends Quest hidden

Import F4SE
Import SUP_F4SE
Import SUP_F4SEVR
Import Utility

Topic property MantellaDialogueLine auto
MantellaRepository property repository auto
MantellaConstants property mConsts auto
Spell property MantellaSpell auto
bool property conversationIsEnding auto
Faction Property MantellaConversationParticipantsFaction Auto
FormList Property Participants auto
Quest Property MantellaConversationParticipantsQuest auto
bool Property UseSimpleTextField = true auto


CustomEvent MantellaConversation_Action_mantella_reload_conversation
CustomEvent MantellaConversation_Action_mantella_end_conversation
CustomEvent MantellaConversation_Action_mantella_remove_character
CustomEvent MantellaConversation_Action_mantella_npc_offended
CustomEvent MantellaConversation_Action_mantella_npc_forgiven
CustomEvent MantellaConversation_Action_mantella_npc_follow

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;           Globals           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

String[] _ingameEvents
String[] _extraRequestActions
bool _does_accept_player_input = false
bool _hasBeenStopped
int _DictionaryCleanTimer
int _PlayerTextInputTimer
string _PlayerTextInput

VoiceType MantellaVoice
Topic MantellaTopic
Actor lastSpokenTo = none
Actor lastNPCSpeaker = none
Actor property playerRef auto

event OnInit()
    _DictionaryCleanTimer = 10
    _PlayerTextInputTimer = 11
    _ingameEvents = new String[0]
    _extraRequestActions = new String[0]    
    RegisterForExternalEvent("OnHttpReplyReceived","OnHttpReplyReceived")
    RegisterForExternalEvent("OnHttpErrorReceived","OnHttpErrorReceived")
    ;mConsts.EVENT_ACTIONS + mConsts.ACTION_RELOADCONVERSATION <- Does not work in Fallout4. Needs to be a raw string 
    ; RegisterForCustomEvent(self, "MantellaConversation_Action_mantella_reload_conversation")
    ; RegisterForCustomEvent(self, "MantellaConversation_Action_mantella_end_conversation")

    MantellaTopic = Game.GetFormFromFile(0x01ED1, "mantella.esp") as Topic
    MantellaVoice = Game.GetFormFromFile(0x2F7A0, "mantella.esp") as VoiceType
    SetPlayerRef()
    SaveSettings()
endEvent

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;    Start new conversation   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function StartConversation(Actor[] actorsToStartConversationWith)
    _hasBeenStopped = false
    if(actorsToStartConversationWith.Length > 2)
        Debug.Notification("Can not start conversation. Conversation is already running.")
        return
    endIf

    _ingameEvents = new string[0]
    _extraRequestActions = new string[0]
    AddActors(actorsToStartConversationWith)

    if(actorsToStartConversationWith.Length < 2)
        Debug.Notification("Not enough characters to start a conversation")
        return
    endIf

    int handle = F4SE_HTTP.createDictionary()
    F4SE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE, mConsts.KEY_REQUESTTYPE_STARTCONVERSATION)
    AddCurrentActorsAndContext(handle)
    F4SE_HTTP.sendLocalhostHttpRequest(handle, mConsts.HTTP_PORT, mConsts.HTTP_ROUTE_MAIN)
    string address = "http://localhost:" + mConsts.HTTP_PORT + "/" + mConsts.HTTP_ROUTE_MAIN
    Debug.Trace("Sent StartConversation http request to " + address)  
    ApplySettings() 
endFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;    Continue conversation    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function AddActorsToConversation(Actor[] actorsToAdd)
    AddActors(actorsToAdd)    
EndFunction

Function RemoveActorsFromConversation(Actor[] actorsToRemove)
    RemoveActors(actorsToRemove)  
EndFunction

function OnHttpReplyReceived(int typedDictionaryHandle)
    string replyType = F4SE_HTTP.getString(typedDictionaryHandle, mConsts.KEY_REPLYTYPE ,"error")
    If (replyType != "error")
        ContinueConversation(typedDictionaryHandle)        
    Else
        string errorMessage = F4SE_HTTP.getString(typedDictionaryHandle, "mantella_message","Error: Could not retrieve error message")
        Debug.Notification(errorMessage)
        CleanupConversation()
    EndIf
endFunction

function ContinueConversation(int handle)
    string nextAction = F4SE_HTTP.getString(handle, mConsts.KEY_REPLYTYPE, "Error: Did not receive reply type")
    ; Debug.Notification(nextAction)
    if(nextAction == mConsts.KEY_REPLYTTYPE_STARTCONVERSATIONCOMPLETED)
        RequestContinueConversation()
    elseIf(nextAction == mConsts.KEY_REPLYTYPE_NPCTALK)
        int npcTalkHandle = F4SE_HTTP.getNestedDictionary(handle, mConsts.KEY_REPLYTYPE_NPCTALK)
        ProcessNpcSpeak(npcTalkHandle)
        RequestContinueConversation()
    elseIf(nextAction == mConsts.KEY_REPLYTYPE_PLAYERTALK)
        If (repository.microphoneEnabled)
            Debug.Notification("Listening...")
            sendRequestForVoiceTranscribe()
        Else
            Debug.Notification("Awaiting player text input...")
            _does_accept_player_input = True
        EndIf
    elseIf (nextAction == mConsts.KEY_REQUESTTYPE_TTS)
        string transcribe = F4SE_HTTP.getString(handle, mConsts.KEY_TRANSCRIBE, "*Complete gibberish*")
        if repository.allowVision
            repository.GenerateMantellaVision()
        endif
        sendRequestForPlayerInput(transcribe)
        repository.ResetEventSpamBlockers() ;reset spam blockers to allow the Listener Script to pick up on those again
        Debug.Notification("Thinking...")
        
    elseIf(nextAction == mConsts.KEY_REPLYTYPE_ENDCONVERSATION)
        CleanupConversation()
    endIf
endFunction

function RequestContinueConversation()
    if _hasBeenStopped ==false
        int handle = F4SE_HTTP.createDictionary()
        F4SE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE, mConsts.KEY_REQUESTTYPE_CONTINUECONVERSATION)
        AddCurrentActorsAndContext(handle)
        if(_extraRequestActions && _extraRequestActions.Length > 0)
            Debug.Trace("_extraRequestActions contains items. Sending them along with continue!")
            F4SE_HTTP.setStringArray(handle, mConsts.KEY_REQUEST_EXTRA_ACTIONS, _extraRequestActions)
            ClearExtraRequestAction()
            Debug.Trace("_extraRequestActions got cleared. Remaining items: " + _extraRequestActions.Length)
        endif
        F4SE_HTTP.sendLocalhostHttpRequest(handle, mConsts.HTTP_PORT, mConsts.HTTP_ROUTE_MAIN)
    endif
endFunction

function ProcessNpcSpeak(int handle)
    string speakerName = F4SE_HTTP.getString(handle, mConsts.KEY_ACTOR_SPEAKER, "Error: No speaker transmitted for action 'NPC talk'")
    Actor speaker = GetActorInConversation(speakerName)
  
    if speaker != none
        Actor spokenTo = GetActorSpokenTo(speaker)

        string lineToSpeak = F4SE_HTTP.getString(handle, mConsts.KEY_ACTOR_LINETOSPEAK, "Error: No line transmitted for actor to speak")
        float duration = F4SE_HTTP.getFloat(handle, mConsts.KEY_ACTOR_DURATION, 0)
        string[] actions = F4SE_HTTP.getStringArray(handle, mConsts.KEY_ACTOR_ACTIONS)

        RaiseActionEvent(speaker, lineToSpeak, actions)
        NpcSpeak(speaker, lineToSpeak, spokenTo, duration)
        ;Utility.wait(1.0)

        if speaker != playerRef
            lastNPCSpeaker = speaker
        EndIf
    endIf
endFunction

function NpcSpeak(Actor actorSpeaking, string lineToSay, Actor actorToSpeakTo, float duration)
    
    ;Force every line to 'MantellaVoice00'   
    ;actorSpeaking.SetOverrideVoiceType(MantellaVoice)                       ;ONCE MANTELLA SOFTWARE GETS UPDATED WITH GITHUB COMMIT: Fallout: game engine now handling audio, lipsync and subtitles natively #405 

    int ret = TopicInfoPatcher.PatchTopicInfo(MantellaTopic, lineToSay)          ;Patch the in-memory text to the new value
    if ret != 0
        Debug.Notification("Patcher returned " + ret);                      ; Probably only if len>150
    Endif

    actorSpeaking.SetLookAt(actorToSpeakTo)
    AllSetLookAt(actorSpeaking)
    
    ;Allow time for reading subtitles
    ;Utility.wait(1.0)													    ;ONCE MANTELLA SOFTWARE GETS UPDATED WITH GITHUB COMMIT: Fallout: game engine now handling audio, lipsync and subtitles natively #405 
    actorSpeaking.Say(MantellaTopic, abSpeakInPlayersHead=false)
    ;actorSpeaking.SetOverrideVoiceType(none)                               ;ONCE MANTELLA SOFTWARE GETS UPDATED WITH GITHUB COMMIT: Fallout: game engine now handling audio, lipsync and subtitles natively #405 

    float durationAdjusted = duration - 0.5
    if(durationAdjusted < 0)
        durationAdjusted = 0
    endIf
    Utility.Wait(durationAdjusted)
endfunction

string function GetActorName(actor actorToGetName)
    string actorName = actorToGetName.GetDisplayName()
    int actorID = actorToGetName.GetFactionRank(MantellaConversationParticipantsFaction)
    if actorID > 0
        actorName = actorName + " " + actorID
    endIf
    return actorName
endFunction

Actor function GetActorInConversation(string actorName)
    int i = 0
    While i < Participants.GetSize()
        Actor currentActor = Participants.GetAt(i) as Actor
        if GetActorName(currentActor) == actorName
            return currentActor
        endIf
        i += 1
    EndWhile
    return none
endFunction



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       End conversation      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function EndConversation()
    _hasBeenStopped=true
    int handle = F4SE_HTTP.createDictionary()
    F4SE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE,mConsts.KEY_REQUESTTYPE_ENDCONVERSATION)
    F4SE_HTTP.sendLocalhostHttpRequest(handle, mConsts.HTTP_PORT, mConsts.HTTP_ROUTE_MAIN)
EndFunction

Function CleanupConversation()
    repository.hasPendingVisionCheck=false
    conversationIsEnding = true
    ClearParticipants()
    ClearIngameEvent() 
    _does_accept_player_input = false
    DispelAllMantellaMagicEffectsFromActors()
    If (MantellaConversationParticipantsQuest.IsRunning())
        MantellaConversationParticipantsQuest.Stop()
    EndIf  
    StartTimer(4,_DictionaryCleanTimer)  ;starting timer with ID 10 for 4 seconds
    F4SE_HTTP.clearAllDictionaries() 
    lastNPCSpeaker = none
    RestoreSettings()
EndFunction

Function DispelAllMantellaMagicEffectsFromActors()
    int i=0
    
    While i < Participants.GetSize()
        Actor actorToDispel = Participants.GetAt(i) as actor
        actorToDispel.DispelSpell(MantellaSpell)
        i += 1
    EndWhile
Endfunction


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Timer Management    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Event Ontimer( int TimerID)
    if TimerID==_DictionaryCleanTimer
        ;Spacing how the cleaning of dictionaries and the Stop() function are called because the game crashes on some setups when it's called directly in CleanupConversation()
        Debug.notification("Conversation has ended!") 
        Stop()
    ElseIf TimerID==_PlayerTextInputTimer ;Spacing out the GenerateMantellaVision() to avoid taking a screenshot of the interface
        repository.GenerateMantellaVision()
        sendRequestForPlayerInput(_PlayerTextInput)
        _does_accept_player_input = False
        repository.ResetEventSpamBlockers() ;reset spam blockers to allow the Listener Script to pick up on those again
        Debug.Notification("Thinking...")
    Endif
Endevent
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Handle player speaking    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function sendRequestForPlayerInput(string playerInput)
    if _hasBeenStopped==false
        AddIngameEvent(repository.constructPlayerState())
        int handle = F4SE_HTTP.createDictionary()
        F4SE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE, mConsts.KEY_REQUESTTYPE_PLAYERINPUT)
        F4SE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE_PLAYERINPUT, playerinput)
        int[] handlesNpcs = BuildNpcsInConversationArray()
        F4SE_HTTP.setNestedDictionariesArray(handle, mConsts.KEY_ACTORS, handlesNpcs)    
        int handleContext = BuildContext()
        F4SE_HTTP.setNestedDictionary(handle, mConsts.KEY_CONTEXT, handleContext)

        ClearIngameEvent()    
        F4SE_HTTP.sendLocalhostHttpRequest(handle, mConsts.HTTP_PORT, mConsts.HTTP_ROUTE_MAIN)
    endif
endFunction

function sendRequestForVoiceTranscribe()
    int handle = F4SE_HTTP.createDictionary()
    F4SE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE, mConsts.KEY_REQUESTTYPE_TTS)
    string[] namesInConversation = new string[Participants.GetSize()]
    int i = 0
    While i < Participants.GetSize()
        namesInConversation[i] = (Participants.GetAt(i) as Actor).GetDisplayName()
        i += 1
    EndWhile
    F4SE_HTTP.setStringArray(handle, mConsts.KEY_INPUT_NAMESINCONVERSATION, namesInConversation)
    F4SE_HTTP.sendLocalhostHttpRequest(handle, mConsts.HTTP_PORT, mConsts.HTTP_ROUTE_STT)
endFunction

function GetPlayerTextInput(string entrytype)
    ;disable for VR
    if !repository.isFO4VR
        if entryType == "playerResponseTextEntry" && _does_accept_player_input
            if UseSimpleTextField
                repository.GetTextInput(self as ScriptObject,"SetPlayerResponseTextInput","Enter Mantella text dialogue")
                ;SimpleTextField.Open(self as ScriptObject, "SetPlayerResponseTextInput","Enter Mantella text dialogue")
            Else
                TIM:TIM.Open(1,"Enter Mantella text dialogue","", 2, 250)
                RegisterForExternalEvent("TIM::Accept","SetPlayerResponseTextInput")
                RegisterForExternalEvent("TIM::Cancel","NoTextInput")
            EndIf
        elseif entryType == "gameEventEntry"
            if UseSimpleTextField
                repository.GetTextInput(self as ScriptObject, "SetGameEventTextInput","Enter Mantella a new game event log")
            Else
                TIM:TIM.Open(1,"Enter Mantella a new game event log","", 2, 250)
                RegisterForExternalEvent("TIM::Accept","SetGameEventTextInput")
                RegisterForExternalEvent("TIM::Cancel","NoTextInput")
            EndIf
        elseif entryType == "playerResponseTextAndVisionEntry"
            if UseSimpleTextField
                repository.GetTextInput(self as ScriptObject, "SetPlayerResponseTextAndVisionInput","Enter Mantella text dialogue")
            Else
                TIM:TIM.Open(1,"Enter Mantella text dialogue","", 2, 250)
                RegisterForExternalEvent("TIM::Accept","SetPlayerResponseTextAndVisionInput")
                RegisterForExternalEvent("TIM::Cancel","NoTextInput")
                EndIf
        endif
    endif
endFunction

Function SetPlayerResponseTextInput(string text)
    ;disable for VR
    if !repository.isFO4VR
        If UseSimpleTextField
            text =repository.SUPF4SEformatText(text)
            if text==""
                return
            Endif
        Else
            UnRegisterForExternalEvent("TIM::Accept")
            UnRegisterForExternalEvent("TIM::Cancel")
        EndIf

        _PlayerTextInput=text
        if repository.allowVision
            StartTimer(0.3,_PlayerTextInputTimer) ;Spacing out the GenerateMantellaVision() to avoid taking a screenshot of the interface
        else
            sendRequestForPlayerInput(_PlayerTextInput)
            _does_accept_player_input = False
            repository.ResetEventSpamBlockers() ;reset spam blockers to allow the ListenerScript to pick up on those again
            Debug.notification("Thinking...")
        Endif
    endif
EndFunction

Function SetPlayerResponseTextAndVisionInput(string text)
    ;Debug.notification("This text input was entered "+ text)
    if !repository.isFO4VR
        If UseSimpleTextField
            text =repository.SUPF4SEformatText(text)
            if text == ""
                return
            Endif
        Else
            UnRegisterForExternalEvent("TIM::Accept")
            UnRegisterForExternalEvent("TIM::Cancel")
        EndIf

        _PlayerTextInput = text
        repository.hasPendingVisionCheck=true
        StartTimer(0.3,_PlayerTextInputTimer)
    endif
EndFunction

Function SetGameEventTextInput(string text)
    ;disable for VR
    ;Debug.notification("This text input was entered "+ text)
    if !repository.isFO4VR
        If UseSimpleTextField
            text =repository.SUPF4SEformatText(text)
            if text == ""
                return
            Endif
        Else
            UnRegisterForExternalEvent("TIM::Accept")
            UnRegisterForExternalEvent("TIM::Cancel")
        EndIf
        AddIngameEvent(text)
    endif
EndFunction

    ;
Function NoTextInput(string text)
    ;disable for VR
    ;Debug.notification("Text input cancelled")
    if !repository.isFO4VR
        UnRegisterForExternalEvent("TIM::Accept")
        UnRegisterForExternalEvent("TIM::Cancel")
    endif
EndFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       Action handler        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function RaiseActionEvent(Actor speaker, string lineToSpeak, string[] actions)
    if(!actions || actions.Length == 0)
        return ;dont send out an action event if there are no actions to act upon
    endIf

    int i = 0
    While i < actions.Length
        string extraAction = actions[i]
        Debug.Trace("Received action " + extraAction + ". Sending out event!")
        TriggerCorrectCustomEvent(extraAction, speaker, lineToSpeak)
        i += 1
    EndWhile    
EndFunction

Function TriggerCorrectCustomEvent(string actionIdentifier, Actor speaker, string lineToSpeak)
    Var[] kargs = new Var[2]
    kargs[0] = speaker
    kargs[1] = lineToSpeak
    if(actionIdentifier == mConsts.ACTION_RELOADCONVERSATION)
        SendCustomEvent("MantellaConversation_Action_mantella_reload_conversation", kargs)
        TriggerReloadConversation()        
    ElseIf (actionIdentifier == mConsts.ACTION_ENDCONVERSATION)
        SendCustomEvent("MantellaConversation_Action_mantella_end_conversation", kargs)
        EndConversation()
    ElseIf (actionIdentifier == mConsts.ACTION_REMOVECHARACTER)
        SendCustomEvent("MantellaConversation_Action_mantella_remove_character", kargs)
        Actor[] actors = new Actor[1]
        actors[0] = speaker as Actor
        RemoveActors(actors)
    ElseIf (actionIdentifier == mConsts.ACTION_NPC_OFFENDED)
        SendCustomEvent("MantellaConversation_Action_mantella_npc_offended", kargs)
    ElseIf (actionIdentifier == mConsts.ACTION_NPC_FORGIVEN)
        SendCustomEvent("MantellaConversation_Action_mantella_npc_forgiven", kargs)
    ElseIf (actionIdentifier == mConsts.ACTION_NPC_FOLLOW)
        SendCustomEvent("MantellaConversation_Action_mantella_npc_follow", kargs)
        Faction CompanionFaction = Game.GetForm(0x000023C01) as Faction
        ;NPCs not yet available as companions have -1 faction rank
        if repository.allowNPCsStayInPlace && repository.allowNPCsStayInPlace && !speaker.IsinFaction(CompanionFaction) || speaker.GetFactionRank(CompanionFaction) < 0
            Debug.Notification(speaker.GetDisplayName() + " is following")
            speaker.SetPlayerTeammate(true)
            speaker.EvaluatePackage()
        EndIf
    endIf
endFunction

Function AddExtraRequestAction(string extraAction)
    if(!_extraRequestActions)
        _extraRequestActions = new string[0]
    endif
    _extraRequestActions.Add(extraAction)
EndFunction

Function ClearExtraRequestAction()
    _extraRequestActions.Clear()
EndFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;        Ingame events        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function AddIngameEvent(string eventText)
    if(!_ingameEvents)
        _ingameEvents = new string[0]
    endif
    _ingameEvents.Add(eventText)
EndFunction

Function ClearIngameEvent()
    _ingameEvents.Clear()
EndFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Action: Reload conversation ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function TriggerReloadConversation()
    ;Debug.Trace("OnReloadConversationActionReceived triggered")
    AddExtraRequestAction(mConsts.ACTION_RELOADCONVERSATION)
endFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       Error handling        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function OnHttpErrorReceived(int typedDictionaryHandle)
    string errorMessage = F4SE_HTTP.getString(typedDictionaryHandle, mConsts.HTTP_ERROR ,"error")
    If (errorMessage != "error")
        Debug.Notification("Received F4SE_HTTP error: " + errorMessage)        
        CleanupConversation()
    Else
        Debug.Notification("Error: Could not retrieve error")
        CleanupConversation()
    EndIf
endFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;            Utils            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function SetPlayerRef()
    playerRef = playerRef
endfunction

bool Function IsPlayerInConversation()
    int i = 0
    While i < Participants.GetSize()
        if (Participants.GetAt(i) == playerRef)
            return true
        endif
        i += 1
    EndWhile
    return false    
EndFunction

Bool function IsActorInConversation(Actor ActorRef)      
    int i = 0
    While i < Participants.GetSize()
        Actor currentActor = Participants.GetAt(i) as Actor
        if currentActor == ActorRef
            return true
        endIf
        i += 1
    EndWhile
    return false
endFunction

Function CauseReassignmentOfParticipantAlias()
    ;This causes Mantella NPC to change AI packages so that they enter specific behavior (usually staying in place while the player talks to them) 
    If (MantellaConversationParticipantsQuest.IsRunning())
        ;Debug.Notification("Stopping MantellaConversationParticipantsQuest")
        MantellaConversationParticipantsQuest.Stop()
    EndIf
    if repository.allowNPCsStayInPlace
        ;Debug.Notification("Starting MantellaConversationParticipantsQuest to asign QuestAlias")
        MantellaConversationParticipantsQuest.Start()
    endif
EndFunction

Function AddActors(Actor[] actorsToAdd)
    int i = 0
    bool wasNewActorAdded = false
    While i < actorsToAdd.Length
        int pos = Participants.Find(actorsToAdd[i])
        if(pos < 0)
            Participants.AddForm(actorsToAdd[i])
            actorsToAdd[i].AddToFaction(MantellaConversationParticipantsFaction)
            wasNewActorAdded = true

            ; check if there are multiple actors with the same name
            int nameCount = 0
            int j = 0
            bool break = false
            if (actorsToAdd[i] != playerRef) ; ignore the player having the same name as an actor
                While (j < Participants.GetSize()) && (break==false)
                    Actor currentActor = Participants.GetAt(j) as Actor
                    if (currentActor.GetDisplayName() == actorsToAdd[i].GetDisplayName())
                        nameCount += 1
                        if (currentActor == actorsToAdd[i]) ; stop counting when the exact actor is found (not just the same name)
                            break = true
                        endIf
                    endIf
                    j += 1
                EndWhile

                if (nameCount > 1)
                    ; set an ID to this non-uniquely-named actor in the form of a faction rank
                    ; these uniquely ID'd names can be called via the GetActorName() function
                    actorsToAdd[i].SetFactionRank(MantellaConversationParticipantsFaction, nameCount)
                endIf
            endIf
        endIf
        i += 1
    EndWhile
    If (wasNewActorAdded)
        CauseReassignmentOfParticipantAlias()
    EndIf
    
    ;PrintActorsInConversation()
EndFunction

Function StopFollowing(Actor tmpActor)
    Faction CompanionFaction = Game.GetForm(0x000023C01) as Faction
    tmpActor.RemoveFromFaction(MantellaConversationParticipantsFaction)
    if !tmpActor.IsinFaction(CompanionFaction) || tmpActor.GetFactionRank(CompanionFaction) < 0
        tmpActor.SetPlayerTeammate(false)
        ;speaker.EvaluatePackage()
    EndIf

EndFunction

Function RemoveActors(Actor[] actorsToRemove)
    ;PrintActorsArray("Actors to remove: ",actorsToRemove)
    bool wasActorRemoved = false
    int i = 0
    While (i < actorsToRemove.Length)
        Actor tmpActor = actorsToRemove[i] as Actor
        If (Participants.HasForm(tmpActor))
            Participants.RemoveAddedForm(tmpActor)
            StopFollowing(tmpActor)
            wasActorRemoved = true
        EndIf
        i += 1
    EndWhile
    if (Participants.GetSize() < 2)
        EndConversation()
    ElseIf (wasActorRemoved)
        CauseReassignmentOfParticipantAlias()
    endIf
    ;PrintActorsInConversation()
EndFunction

Function ClearParticipants()
    int i = 0
    While i < Participants.GetSize()
        Actor tmpActor = Participants.GetAt(i) as Actor
        StopFollowing(tmpActor)
        i += 1
    EndWhile
    Participants.Revert()
EndFunction

bool Function ContainsActor(Actor[] arrayToCheck, Actor actorCheckFor)
    int i = 0
    While i < arrayToCheck.Length
        If (arrayToCheck[i] == actorCheckFor)
            return True
        EndIf
        i += 1
    EndWhile
    return False
EndFunction

Function PrintActorsArray(string prefix, Actor[] actors)
    int i = 0
    string actor_message = ""
    While i < actors.Length
        actor_message += GetActorName(actors[i]) + ", "
        i += 1
    EndWhile
    Debug.Notification(prefix + actor_message)
EndFunction

Function PrintActorsInConversation()
    int i = 0
    string actor_message = ""
    While i < Participants.GetSize()
        actor_message += GetActorName(Participants.GetAt(i) as Actor) + ", "
        i += 1
    EndWhile
    Debug.Notification(actor_message)
EndFunction

int Function CountActorsInConversation()
    return Participants.GetSize()
EndFunction

Actor Function GetActorInConversationByIndex(int indexOfActor) 
    If (indexOfActor >= 0 && indexOfActor < Participants.getSize())
        return Participants.GetAt(indexOfActor) as Actor
    EndIf
    return none
EndFunction

Function AddCurrentActorsAndContext(int handleToAddTo)
    ;Add Actors
    int[] handlesNpcs = BuildNpcsInConversationArray()
    F4SE_HTTP.setNestedDictionariesArray(handleToAddTo, mConsts.KEY_ACTORS, handlesNpcs)
    ;add context
    int handleContext = BuildContext()
    F4SE_HTTP.setNestedDictionary(handleToAddTo, mConsts.KEY_CONTEXT, handleContext)
EndFunction

int[] function BuildNpcsInConversationArray()
    int[] actorHandles =  new int[Participants.GetSize()]
    int i = 0
    While i < Participants.GetSize()
        actorHandles[i] = buildActorSetting(Participants.GetAt(i) as Actor)
        i += 1
    EndWhile
    return actorHandles
endFunction

Function AllSetLookAt(Actor speaker)                        ; make sure everybody in converstation is looking at speaker
    int i = 0
    While i < Participants.GetSize()
        Actor tmpActor = Participants.GetAt(i) as Actor 
        if speaker != tmpActor
            tmpActor.SetLookAt(speaker)
        EndIf
        i += 1
    EndWhile
EndFunction

Actor Function GetActorSpokenTo(Actor speaker)
    Actor spokenTo

    If IsPlayerInConversation()                           ; single and multi-NPCs. Either PC or NPC can talk first
        if speaker != playerRef
            spokenTo  = playerRef
        Else
            spokenTo = lastNPCSpeaker
        EndIf
    Else                                                    ; Radiant conversation w/2 NPCs or new player convo w/ single NPC
        If speaker == Participants.GetAt(0)
            spokenTo = Participants.GetAt(1) as Actor
        Else
            spokenTo = Participants.GetAt(0) as Actor
        EndIf
    Endif

    return spokenTo
EndFunction


int function buildActorSetting(Actor actorToBuild)    
    int handle = F4SE_HTTP.createDictionary()
    F4SE_HTTP.setInt(handle, mConsts.KEY_ACTOR_BASEID, (actorToBuild.getactorbase() as form).getformid())
    F4SE_HTTP.setInt(handle, mConsts.KEY_ACTOR_REFID, (actorToBuild as form).getformid())
    F4SE_HTTP.setString(handle, mConsts.KEY_ACTOR_NAME, actorToBuild.GetDisplayName())
    F4SE_HTTP.setBool(handle, mConsts.KEY_ACTOR_ISPLAYER, actorToBuild == playerRef)
    F4SE_HTTP.setInt(handle, mConsts.KEY_ACTOR_GENDER, actorToBuild.getleveledactorbase().getsex())
    F4SE_HTTP.setString(handle, mConsts.KEY_ACTOR_RACE, actorToBuild.getrace())
    F4SE_HTTP.setInt(handle, mConsts.KEY_ACTOR_RELATIONSHIPRANK, actorToBuild.getrelationshiprank(playerRef))
    F4SE_HTTP.setString(handle, mConsts.KEY_ACTOR_VOICETYPE, actorToBuild.GetVoiceType())
    F4SE_HTTP.setBool(handle, mConsts.KEY_ACTOR_ISINCOMBAT, actorToBuild.IsInCombat())    
    F4SE_HTTP.setBool(handle, mConsts.KEY_ACTOR_ISENEMY, actorToBuild.getcombattarget() == playerRef)
    int customValuesHandle = BuildCustomActorValues(actorToBuild)
    F4SE_HTTP.setNestedDictionary(handle, mConsts.KEY_ACTOR_CUSTOMVALUES, customValuesHandle)  
    return handle
endFunction

int Function BuildCustomActorValues(Actor actorToBuildCustomValuesFor)
    int handleCustomActorValues = F4SE_HTTP.createDictionary()
    F4SE_HTTP.setFloat(handleCustomActorValues, mConsts.KEY_ACTOR_CUSTOMVALUES_POSX, actorToBuildCustomValuesFor.getpositionX())
    F4SE_HTTP.setFloat(handleCustomActorValues, mConsts.KEY_ACTOR_CUSTOMVALUES_POSY, actorToBuildCustomValuesFor.getpositionY())
    return handleCustomActorValues
EndFunction

int function BuildContext()
    int handle = F4SE_HTTP.createDictionary()
    String currLoc = ""
    form currentLocation = playerRef.GetCurrentLocation() as Form
    if currentLocation
        currLoc = currentLocation.getName()
    Else
        currLoc = "Boston area"
    endIf
    F4SE_HTTP.setString(handle, mConsts.KEY_CONTEXT_LOCATION, currLoc)
    F4SE_HTTP.setInt(handle, mConsts.KEY_CONTEXT_TIME, GetCurrentHourOfDay())
    F4SE_HTTP.setStringArray(handle, mConsts.KEY_CONTEXT_INGAMEEVENTS, _ingameEvents)
    int customValuesHandle = BuildCustomContextValues()
    F4SE_HTTP.setNestedDictionary(handle, mConsts.KEY_CONTEXT_CUSTOMVALUES, customValuesHandle)
    return handle
endFunction

int Function BuildCustomContextValues()
    int handleCustomContextValues = F4SE_HTTP.createDictionary()
    F4SE_HTTP.setFloat(handleCustomContextValues, mConsts.KEY_CONTEXT_CUSTOMVALUES_PLAYERPOSX, playerRef.getpositionX())
    F4SE_HTTP.setFloat(handleCustomContextValues, mConsts.KEY_CONTEXT_CUSTOMVALUES_PLAYERPOSY, playerRef.getpositionY())
    F4SE_HTTP.setFloat(handleCustomContextValues, mConsts.KEY_CONTEXT_CUSTOMVALUES_PLAYERROT, playerRef.GetAngleZ())
    bool isVisionReady = repository.checkAndUpdateVisionPipeline()
    if isVisionReady
        F4SE_HTTP.setBool(handleCustomContextValues, mConsts.KEY_CONTEXT_CUSTOMVALUES_VISION_READY, isVisionReady)
        F4SE_HTTP.setString(handleCustomContextValues, mConsts.KEY_CONTEXT_CUSTOMVALUES_VISION_RES, repository.visionResolution)
        F4SE_HTTP.setInt(handleCustomContextValues, mConsts.KEY_CONTEXT_CUSTOMVALUES_VISION_RESIZE, repository.visionResize)
    endif
    if repository.allowVisionHints && repository.ActorsInCellArray!=""
        F4SE_HTTP.setString(handleCustomContextValues, mConsts.KEY_ACTOR_CUSTOMVALUES_VISION_HINTSNAMEARRAY, repository.ActorsInCellArray)
        F4SE_HTTP.setString(handleCustomContextValues, mConsts.KEY_ACTOR_CUSTOMVALUES_VISION_HINTSDISTANCEARRAY, repository.VisionDistanceArray)
        repository.resetVisionHintsArrays()
    endif
    return handleCustomContextValues
EndFunction



int function GetCurrentHourOfDay()
	float Time = Utility.GetCurrentGameTime()
	Time -= Math.Floor(Time) ; Remove "previous in-game days passed" bit
	Time *= 24 ; Convert from fraction of a day to number of hours
	int Hour = Math.Floor(Time) ; Get whole hour
	return Hour
endFunction


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   SUP_F4SE & SUP_F4SEVR functions   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Functions to temporarly change some game settings
; to prevent various NPCs from interrupting conversations in progress
; variables taken from 'You talk too much' https://www.nexusmods.com/fallout4/mods/10570
; Need to use SUP_F4SE storage here, as loading a game resets script variables,
; possibly losing the saved GameSettings
; All Game settings are reset when starting the game

; Save the game's original GameSettings before we modify them at conversation start
Function SaveSettings()
    int SettingsSaved = 0

    
    if repository.currentSUPversion != 0 
        if repository.isFO4VR
            if SUP_F4SEVR.ModLocalDataExists("MantellaConversation", "SettingsSaved")
                SettingsSaved = SUP_F4SEVR.ModLocalDataGetInt("MantellaConversation", "SettingsSaved")
            EndIf
        
            if SettingsSaved == 0
                SUP_F4SEVR.ModLocalDataSetFloat("MantellaConversation",  "fAICommentWaitingForPlayerInput", Game.GetGameSettingFloat("fAICommentWaitingForPlayerInput"))
                SUP_F4SEVR.ModLocalDataSetFloat("MantellaConversation",  "fAISocialchanceForConversation", Game.GetGameSettingFloat("fAISocialchanceForConversation"))
                SUP_F4SEVR.ModLocalDataSetFloat("MantellaConversation",  "fAISocialRadiusToTriggerConversationInterior", Game.GetGameSettingFloat("fAISocialRadiusToTriggerConversationInterior"))
                SUP_F4SEVR.ModLocalDataSetFloat("MantellaConversation",  "fAISocialTimerForConversationsMax", Game.GetGameSettingFloat("fAISocialTimerForConversationsMax"))
                SUP_F4SEVR.ModLocalDataSetFloat("MantellaConversation",  "fAISocialTimerForConversationsMin", Game.GetGameSettingFloat("fAISocialTimerForConversationsMin"))
                SUP_F4SEVR.ModLocalDataSetFloat("MantellaConversation",  "fAISocialchanceForConversationInterior", Game.GetGameSettingFloat("fAISocialchanceForConversationInterior"))
                SUP_F4SEVR.ModLocalDataSetFloat("MantellaConversation",  "fCommentOnPlayerActionsTimer", Game.GetGameSettingFloat("fCommentOnPlayerActionsTimer"))
                SUP_F4SEVR.ModLocalDataSetInt("MantellaConversation",  "iAISocialDistanceToTriggerEvent", Game.GetGameSettingInt("iAISocialDistanceToTriggerEvent"))
                SUP_F4SEVR.ModLocalDataSetFloat("MantellaConversation",  "fAISocialRadiusToTriggerConversation", Game.GetGameSettingFloat("fAISocialRadiusToTriggerConversation"))
                SUP_F4SEVR.ModLocalDataSetFloat("MantellaConversation",  "fAIMinGreetingDistance", Game.GetGameSettingFloat("fAIMinGreetingDistance"))
        
                SUP_F4SEVR.ModLocalDataSetInt("MantellaConversation", "SettingsSaved", 1)
            Endif
        else
            if SUP_F4SE.ModLocalDataExists("MantellaConversation", "SettingsSaved")
                SettingsSaved = SUP_F4SE.ModLocalDataGetInt("MantellaConversation", "SettingsSaved")
            EndIf
        
            if SettingsSaved == 0
                SUP_F4SE.ModLocalDataSetFloat("MantellaConversation",  "fAICommentWaitingForPlayerInput", Game.GetGameSettingFloat("fAICommentWaitingForPlayerInput"))
                SUP_F4SE.ModLocalDataSetFloat("MantellaConversation",  "fAISocialchanceForConversation", Game.GetGameSettingFloat("fAISocialchanceForConversation"))
                SUP_F4SE.ModLocalDataSetFloat("MantellaConversation",  "fAISocialRadiusToTriggerConversationInterior", Game.GetGameSettingFloat("fAISocialRadiusToTriggerConversationInterior"))
                SUP_F4SE.ModLocalDataSetFloat("MantellaConversation",  "fAISocialTimerForConversationsMax", Game.GetGameSettingFloat("fAISocialTimerForConversationsMax"))
                SUP_F4SE.ModLocalDataSetFloat("MantellaConversation",  "fAISocialTimerForConversationsMin", Game.GetGameSettingFloat("fAISocialTimerForConversationsMin"))
                SUP_F4SE.ModLocalDataSetFloat("MantellaConversation",  "fAISocialchanceForConversationInterior", Game.GetGameSettingFloat("fAISocialchanceForConversationInterior"))
                SUP_F4SE.ModLocalDataSetFloat("MantellaConversation",  "fCommentOnPlayerActionsTimer", Game.GetGameSettingFloat("fCommentOnPlayerActionsTimer"))
                SUP_F4SE.ModLocalDataSetInt("MantellaConversation",  "iAISocialDistanceToTriggerEvent", Game.GetGameSettingInt("iAISocialDistanceToTriggerEvent"))
                SUP_F4SE.ModLocalDataSetFloat("MantellaConversation",  "fAISocialRadiusToTriggerConversation", Game.GetGameSettingFloat("fAISocialRadiusToTriggerConversation"))
                SUP_F4SE.ModLocalDataSetFloat("MantellaConversation",  "fAIMinGreetingDistance", Game.GetGameSettingFloat("fAIMinGreetingDistance"))
        
                SUP_F4SE.ModLocalDataSetInt("MantellaConversation", "SettingsSaved", 1)
            Endif
        endif
    endif

EndFunction

; Apply Mantella settings to stop NPCs talking
Function ApplySettings()
    int SettingsSaved = 0

    if repository.currentSUPversion != 0 
        if repository.isFO4VR
            if SUP_F4SEVR.ModLocalDataExists("MantellaConversation", "SettingsSaved")
                SettingsSaved = SUP_F4SEVR.ModLocalDataGetInt("MantellaConversation", "SettingsSaved")
            EndIf

            if SettingsSaved == 0
                SaveSettings()
            Endif

            Game.SetGameSettingFloat("fAICommentWaitingForPlayerInput", 800.0)
            Game.SetGameSettingFloat("fAISocialchanceForConversation", 1.0)
            Game.SetGameSettingFloat("fAISocialRadiusToTriggerConversationInterior", 1.0)
            Game.SetGameSettingFloat("fAISocialTimerForConversationsMax", 800.0)
            Game.SetGameSettingFloat("fAISocialTimerForConversationsMin", 800.0)
            Game.SetGameSettingFloat("fAISocialchanceForConversationInterior", 1.0)
            Game.SetGameSettingFloat("fCommentOnPlayerActionsTimer", 800.0)
            Game.SetGameSettingInt("iAISocialDistanceToTriggerEvent", 1)
            Game.SetGameSettingFloat("fAISocialRadiusToTriggerConversation", 1.0)
            Game.SetGameSettingFloat("fAIMinGreetingDistance", 1.0)

            SUP_F4SEVR.ModLocalDataSetInt("MantellaConversation", "SettingsApplied", 1)
        else
            if SUP_F4SE.ModLocalDataExists("MantellaConversation", "SettingsSaved")
                SettingsSaved = SUP_F4SE.ModLocalDataGetInt("MantellaConversation", "SettingsSaved")
            EndIf

            if SettingsSaved == 0
                SaveSettings()
            Endif

            Game.SetGameSettingFloat("fAICommentWaitingForPlayerInput", 800.0)
            Game.SetGameSettingFloat("fAISocialchanceForConversation", 1.0)
            Game.SetGameSettingFloat("fAISocialRadiusToTriggerConversationInterior", 1.0)
            Game.SetGameSettingFloat("fAISocialTimerForConversationsMax", 800.0)
            Game.SetGameSettingFloat("fAISocialTimerForConversationsMin", 800.0)
            Game.SetGameSettingFloat("fAISocialchanceForConversationInterior", 1.0)
            Game.SetGameSettingFloat("fCommentOnPlayerActionsTimer", 800.0)
            Game.SetGameSettingInt("iAISocialDistanceToTriggerEvent", 1)
            Game.SetGameSettingFloat("fAISocialRadiusToTriggerConversation", 1.0)
            Game.SetGameSettingFloat("fAIMinGreetingDistance", 1.0)

            SUP_F4SE.ModLocalDataSetInt("MantellaConversation", "SettingsApplied", 1)
        endif
    endif
EndFunction

; Restore settings after conversation ends
Function RestoreSettings()
    int SettingsSaved = 0
    int SettingsApplied = 0
    if repository.currentSUPversion != 0 
        if repository.isFO4VR
            if SUP_F4SEVR.ModLocalDataExists("MantellaConversation", "SettingsSaved")
                SettingsSaved = SUP_F4SEVR.ModLocalDataGetInt("MantellaConversation", "SettingsSaved")
            EndIf

            if SUP_F4SEVR.ModLocalDataExists("MantellaConversation", "SettingsApplied")
                SettingsApplied = SUP_F4SEVR.ModLocalDataGetInt("MantellaConversation", "SettingsApplied")
            EndIf

            if !SettingsSaved
                SaveSettings()
            ElseIf SettingsApplied
                Game.SetGameSettingFloat("fAICommentWaitingForPlayerInput", SUP_F4SEVR.ModLocalDataGetFloat("MantellaConversation", "fAICommentWaitingForPlayerInput"))
                Game.SetGameSettingFloat("fAISocialchanceForConversation", SUP_F4SEVR.ModLocalDataGetFloat("MantellaConversation", "fAISocialchanceForConversation"))
                Game.SetGameSettingFloat("fAISocialRadiusToTriggerConversationInterior", SUP_F4SEVR.ModLocalDataGetFloat("MantellaConversation", "fAISocialRadiusToTriggerConversationInterior"))
                Game.SetGameSettingFloat("fAISocialTimerForConversationsMax", SUP_F4SEVR.ModLocalDataGetFloat("MantellaConversation", "fAISocialTimerForConversationsMax"))
                Game.SetGameSettingFloat("fAISocialTimerForConversationsMin", SUP_F4SEVR.ModLocalDataGetFloat("MantellaConversation", "fAISocialTimerForConversationsMin"))
                Game.SetGameSettingFloat("fAISocialchanceForConversationInterior", SUP_F4SEVR.ModLocalDataGetFloat("MantellaConversation", "fAISocialchanceForConversationInterior"))
                Game.SetGameSettingFloat("fCommentOnPlayerActionsTimer", SUP_F4SEVR.ModLocalDataGetFloat("MantellaConversation", "fCommentOnPlayerActionsTimer"))
                Game.SetGameSettingInt("iAISocialDistanceToTriggerEvent", SUP_F4SEVR.ModLocalDataGetInt("MantellaConversation", "iAISocialDistanceToTriggerEvent"))
                Game.SetGameSettingFloat("fAISocialRadiusToTriggerConversation", SUP_F4SEVR.ModLocalDataGetFloat("MantellaConversation", "fAISocialRadiusToTriggerConversation"))
                Game.SetGameSettingFloat("fAIMinGreetingDistance", SUP_F4SEVR.ModLocalDataGetFloat("MantellaConversation", "fAIMinGreetingDistance"))
            EndIf
            SUP_F4SEVR.ModLocalDataSetInt("MantellaConversation", "SettingsApplied", 0)
        Else
            if SUP_F4SE.ModLocalDataExists("MantellaConversation", "SettingsSaved")
                SettingsSaved = SUP_F4SE.ModLocalDataGetInt("MantellaConversation", "SettingsSaved")
            EndIf

            if SUP_F4SE.ModLocalDataExists("MantellaConversation", "SettingsApplied")
                SettingsApplied = SUP_F4SE.ModLocalDataGetInt("MantellaConversation", "SettingsApplied")
            EndIf

            if !SettingsSaved
                SaveSettings()
            ElseIf SettingsApplied
                Game.SetGameSettingFloat("fAICommentWaitingForPlayerInput", SUP_F4SE.ModLocalDataGetFloat("MantellaConversation", "fAICommentWaitingForPlayerInput"))
                Game.SetGameSettingFloat("fAISocialchanceForConversation", SUP_F4SE.ModLocalDataGetFloat("MantellaConversation", "fAISocialchanceForConversation"))
                Game.SetGameSettingFloat("fAISocialRadiusToTriggerConversationInterior", SUP_F4SE.ModLocalDataGetFloat("MantellaConversation", "fAISocialRadiusToTriggerConversationInterior"))
                Game.SetGameSettingFloat("fAISocialTimerForConversationsMax", SUP_F4SE.ModLocalDataGetFloat("MantellaConversation", "fAISocialTimerForConversationsMax"))
                Game.SetGameSettingFloat("fAISocialTimerForConversationsMin", SUP_F4SE.ModLocalDataGetFloat("MantellaConversation", "fAISocialTimerForConversationsMin"))
                Game.SetGameSettingFloat("fAISocialchanceForConversationInterior", SUP_F4SE.ModLocalDataGetFloat("MantellaConversation", "fAISocialchanceForConversationInterior"))
                Game.SetGameSettingFloat("fCommentOnPlayerActionsTimer", SUP_F4SE.ModLocalDataGetFloat("MantellaConversation", "fCommentOnPlayerActionsTimer"))
                Game.SetGameSettingInt("iAISocialDistanceToTriggerEvent", SUP_F4SE.ModLocalDataGetInt("MantellaConversation", "iAISocialDistanceToTriggerEvent"))
                Game.SetGameSettingFloat("fAISocialRadiusToTriggerConversation", SUP_F4SE.ModLocalDataGetFloat("MantellaConversation", "fAISocialRadiusToTriggerConversation"))
                Game.SetGameSettingFloat("fAIMinGreetingDistance", SUP_F4SE.ModLocalDataGetFloat("MantellaConversation", "fAIMinGreetingDistance"))
            EndIf
            SUP_F4SE.ModLocalDataSetInt("MantellaConversation", "SettingsApplied", 0)
        endif
    endif
EndFunction



