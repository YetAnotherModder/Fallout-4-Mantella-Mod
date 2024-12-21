Scriptname MantellaConversation extends Quest hidden

Import F4SE
Import Utility

Topic property MantellaDialogueLine auto
MantellaRepository property repository auto
MantellaConstants property mConsts auto
Spell property MantellaSpell auto
bool property conversationIsEnding auto
Faction Property MantellaConversationParticipantsFaction Auto
Faction Property MantellaFunctionTargetFaction Auto
FormList Property Participants auto
Quest Property MantellaConversationParticipantsQuest auto
SPELL Property MantellaIsTalkingSpell Auto
bool Property UseSimpleTextField = true auto
Potion Property StimpackItem auto


CustomEvent MantellaConversation_Action_mantella_reload_conversation
CustomEvent MantellaConversation_Action_mantella_end_conversation
CustomEvent MantellaConversation_Action_mantella_remove_character
CustomEvent MantellaConversation_Action_mantella_npc_offended
CustomEvent MantellaConversation_Action_mantella_npc_forgiven
CustomEvent MantellaConversation_Action_mantella_npc_follow
CustomEvent MantellaConversation_Action_mantella_npc_inventory
CustomEvent DelayedCustomEventTrigger

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
Actor _lastNpcToSpeak = none
Actor property playerRef auto
Actor CurrentFunctionTargetNPC
bool _isTalking = false
int HttpTimeout
int _HttpPollTimer = 12 const
float HttpPeriod = 0.2
bool property HttpPolling = false auto             ; polling mode, used by VR
bool PollTimerActive
bool _shouldRespond = true

int _delayedHandle
string[] _delayedActionIdentifier
actor[] _delayedSpeaker 
string[] _delayedlineToSpeak

;AI PackageManagement variables, used to track the position of an actor and reset their AI package in case they get stuck in the same place
int RestartLootTimer = 1
float StoredActorPositionX
float StoredActorPositionY
float StoredActorPositionZ
Actor trackedPositionActor
bool SettingsSaved = false
bool SettingsApplied = false

event OnInit()
    _DictionaryCleanTimer = 10
    _PlayerTextInputTimer = 11
    _ingameEvents = new String[0]
    _extraRequestActions = new String[0]    
    MantellaTopic = Game.GetFormFromFile(0x01ED1, "mantella.esp") as Topic
    MantellaVoice = Game.GetFormFromFile(0x2F7A0, "mantella.esp") as VoiceType
    SetPlayerRef()
    SaveSettings()
    repository.NPCAIPackageSelector=-1
    if !UI.isMenuRegistered(SimpleTextField.GetMenuName())
        SimpleTextField:Program.GetProgram().OnQuestInit()              ; Make sure SimpleTextField is initialized
    Endif
    ;repository.microphoneEnabled = repository.isFO4VR
endEvent

;Get some important variables set before anything else starts
Function OnLoadGame()
    HttpPolling = repository.isFO4VR
    if !HttpPolling
        RegisterForKey(0x97)
        Debug.Notification("Interrupt mode")
    Else
        UnregisterForKey(0x97)
        Debug.Notification("Polling mode")
    EndIf
EndFunction


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;    Start new conversation   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function StartConversation(Actor[] actorsToStartConversationWith)
    if(actorsToStartConversationWith.Length > 2)
        Debug.Notification("Can not start conversation. Conversation is already running.")
        return
    elseIf(actorsToStartConversationWith.Length < 2)
        Debug.Notification("Not enough characters to start a conversation")
        return
    endIf

    int handle = F4SE_HTTP.createDictionary()
    ;F4SE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE, mConsts.KEY_REQUESTTYPE_INIT)
    ; send request to initialize Mantella settings (set LLM connection, start up TTS service, load character_df etc) 
    ; while waiting for actor info and context to be prepared below
    ;sendHTTPRequest(handle, mConsts.HTTP_ROUTE_MAIN, mConsts.KEY_REQUESTTYPE_INIT)

    _delayedHandle=0
    _delayedActionIdentifier = new String[100]
    _delayedSpeaker = new Actor[100]
    _delayedlineToSpeak = new String[100]
    _hasBeenStopped = false
    _ingameEvents = new string[0]
    _extraRequestActions = new string[0]

    AddActors(actorsToStartConversationWith)

    if repository.microphoneEnabled
        F4SE_HTTP.setString(handle, mConsts.KEY_INPUTTYPE, mConsts.KEY_INPUTTYPE_MIC)
    Else
        F4SE_HTTP.setString(handle, mConsts.KEY_INPUTTYPE, mConsts.KEY_INPUTTYPE_TEXT)
    endIf

    F4SE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE, mConsts.KEY_REQUESTTYPE_STARTCONVERSATION)
    AddCurrentActorsAndContext(handle)
    sendHTTPRequest(handle,mConsts.HTTP_ROUTE_MAIN, mConsts.KEY_REQUESTTYPE_STARTCONVERSATION)
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
        if repository.allowFunctionCalling
            repository.resetFunctionInferenceNPCArrays()
            repository.UpdateFunctionInferenceNPCArrays(repository.GetFunctionInferenceActorList())
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
            ;Debug.Trace("_extraRequestActions contains items. Sending them along with continue!")
            F4SE_HTTP.setStringArray(handle, mConsts.KEY_REQUEST_EXTRA_ACTIONS, _extraRequestActions)
            ClearExtraRequestAction()
            ;Debug.Trace("_extraRequestActions got cleared. Remaining items: " + _extraRequestActions.Length)
        endif
        sendHTTPRequest(handle,mConsts.HTTP_ROUTE_MAIN, mConsts.KEY_REQUESTTYPE_CONTINUECONVERSATION)
    endif
endFunction

function ProcessNpcSpeak(int handle)
    string speakerName = F4SE_HTTP.getString(handle, mConsts.KEY_ACTOR_SPEAKER, "Error: No speaker transmitted for action 'NPC talk'")
    Actor speaker = GetActorInConversation(speakerName)
  
    if speaker != none
        Actor spokenTo = GetActorSpokenTo(speaker)
        ;WaitForNpcToFinishSpeaking(speaker, _lastNpcToSpeak,-1)
        string lineToSpeak = F4SE_HTTP.getString(handle, mConsts.KEY_ACTOR_LINETOSPEAK, "Error: No line transmitted for actor to speak")
        float duration = F4SE_HTTP.getFloat(handle, mConsts.KEY_ACTOR_DURATION, 0)
        string[] actions = F4SE_HTTP.getStringArray(handle, mConsts.KEY_ACTOR_ACTIONS)

        RaiseActionEvent(speaker, lineToSpeak, actions, handle)
        NpcSpeak(speaker, lineToSpeak, spokenTo, duration)
        ;Utility.wait(1.0)

        if speaker != playerRef
            _lastNpcToSpeak = speaker
        EndIf
    endIf
endFunction

function NpcSpeak(Actor actorSpeaking, string lineToSay, Actor actorToSpeakTo, float duration)
    actorSpeaking.SetOverrideVoiceType(MantellaVoice)                       ;Force every line to 'MantellaVoice00'   
 
    int ret = TopicInfoPatcher.PatchTopicInfo(MantellaTopic, lineToSay)          ;Patch the in-memory text to the new value
    if ret != 0
        Debug.Notification("Patcher returned " + ret);                      ; Probably only if len>150
    Endif

    actorSpeaking.SetLookAt(actorToSpeakTo)
    AllSetLookAt(actorSpeaking)
    
    actorSpeaking.Say(MantellaTopic, abSpeakInPlayersHead=false)
    actorSpeaking.SetOverrideVoiceType(none)
    
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

Function SetIsTalking(bool isTalking)
    _isTalking = isTalking
EndFunction

bool Function GetIsTalking()
    return _isTalking
EndFunction


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       End conversation      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function EndConversation()
    _hasBeenStopped=true
    int handle = F4SE_HTTP.createDictionary()
    F4SE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE,mConsts.KEY_REQUESTTYPE_ENDCONVERSATION)
    sendHTTPRequest(handle,mConsts.HTTP_ROUTE_MAIN,mConsts.KEY_REQUESTTYPE_ENDCONVERSATION)
EndFunction

Function CleanupConversation()
    _delayedHandle=0
    repository.NPCAIPackageSelector=-1
    repository.hasPendingVisionCheck=false
    conversationIsEnding = true
    ClearParticipants()
    ClearIngameEvent() 
    _does_accept_player_input = false
    _isTalking = false
    DispelSpellFromActorsInConversation(MantellaSpell)
    DispelSpellFromActorsInConversation(MantellaIsTalkingSpell)
    RemoveAllParticipantsFromFaction(MantellaFunctionTargetFaction)
    If (MantellaConversationParticipantsQuest.IsRunning())
        MantellaConversationParticipantsQuest.Stop()
    EndIf  
    StartTimer(4,_DictionaryCleanTimer)  ;starting timer with ID 10 for 4 seconds
    F4SE_HTTP.clearAllDictionaries() 
    _lastNpcToSpeak = none
    RestoreSettings()
EndFunction

Function DispelSpellFromActorsInConversation(Spell SpellToDispel)
    int i=0
    
    While i < Participants.GetSize()
        Actor actorToDispel = Participants.GetAt(i) as actor
        actorToDispel.DispelSpell(SpellToDispel)
        i += 1
    EndWhile
Endfunction

Function RemoveAllParticipantsFromFaction(faction factionToRemove)
    int i=0
    
    While i < Participants.GetSize()
        Actor actorToRemove = Participants.GetAt(i) as actor
        actorToRemove.RemoveFromFaction(factionToRemove)
        i += 1
    EndWhile
Endfunction

function OnHttpReplyReceived(int typedDictionaryHandle)
    string replyType = F4SE_HTTP.getString(typedDictionaryHandle, mConsts.KEY_REPLYTYPE ,"error")
    IF replyType == mConsts.KEY_REPLYTTYPE_INITCOMPLETED
        _shouldRespond = false
    ElseIf (replyType != "error")
        _shouldRespond = true
        ContinueConversation(typedDictionaryHandle)        
    Else
        string errorMessage = F4SE_HTTP.getString(typedDictionaryHandle, "mantella_message","Error: Could not retrieve error message")
        Debug.Notification(errorMessage)
        CleanupConversation()
    EndIf
endFunction

; Send a request to Mantella app and setup polling if enabled
Function sendHTTPRequest(int handle, string route, string request)
    if _shouldRespond
        F4SE_HTTP.sendLocalhostHttpRequest(handle, mConsts.HTTP_PORT, route)
    else
        _shouldRespond = true
    endIf

    ; Set two minute timeout, enough for LLM retries
    if HttpPolling                 ; Used for FO4VR
        HttpTimeout = 400          ; should be in config
        HttpPeriod = 0.3
    Else
        HttpPeriod = 0.5           ; Secondary data check, sometimes signal keystroke gets lost :-(
        HttpTimeout = 240
    EndIf
    SetPolling()
EndFunction

int Function CheckForHttpReply()                   ; Retrieve messages from Mantella app, if available
    int handle = F4SE_HTTP.GetHandle()
    If handle != -1
        PollTimerActive = false
        CancelTimer(_HttpPollTimer)
        if handle >= 100000                         ; Used to indicate error
            OnHttpErrorReceived(handle - 100000)
        Else
            OnHttpReplyReceived(handle)
        Endif
    Else
        SetPolling()
    EndIf
    return handle
EndFunction

Function SetPolling()                           ; Set timer for next message check
    HttpTimeout -= 1
    PollTimerActive = true
    If HttpTimeout > 0 
        CancelTimer(_HttpPollTimer)
        StartTimer(HttpPeriod, _HttpPollTimer)
    Else
        Debug.Notification("HTTP Timeout")
        CleanupConversation()
    Endif
EndFunction

; F4SE_HTTP signals us that data is ready by sending a 0x97 keycode
Event OnKeyDown(int keycode)
    if keycode == 0x97 && !HttpPolling                ; 0x97 = Signal from F4SE_HTTP
        int gotData = CheckForHttpReply()
    EndIf
EndEvent

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
    elseif TimerID==RestartLootTimer && repository.NPCAIPackageSelector==3
        If trackedPositionActor.IsOverEncumbered()
            debug.notification(trackedPositionActor.GetDisplayName()+" cannot scavenge anymore because they are overemcumbered.") 
            repository.NPCAIPackageSelector==0
            CauseReassignmentOfParticipantAlias()
        EndIf
        float currentPositionX = trackedPositionActor.getpositionX()
        float currentPositionY = trackedPositionActor.getpositionY()
        float currentPositionZ = trackedPositionActor.getpositionZ()      
        if currentPositionX==StoredActorPositionX && currentPositionY==StoredActorPositionY &&  currentPositionZ==StoredActorPositionZ
            StoredActorPositionX=currentPositionX
            StoredActorPositionY=currentPositionY
            StoredActorPositionZ=currentPositionZ
            CauseReassignmentOfParticipantAlias()
        Else
            StoredActorPositionX=currentPositionX
            StoredActorPositionY=currentPositionY
            StoredActorPositionZ=currentPositionZ
        endif
        StartTimer(4,RestartLootTimer) 
    ElseIf TimerID == _HttpPollTimer  ; Used with VR, need to poll for HTTP received data
        if PollTimerActive
            int gotData = CheckForHttpReply()
            ;if gotData != -1
            ;Endif
        Endif
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
        sendHTTPRequest(handle,mConsts.HTTP_ROUTE_MAIN, mConsts.KEY_REQUESTTYPE_PLAYERINPUT)
        endif
endFunction

function sendRequestForVoiceTranscribe()
    sendRequestForPlayerInput("")
endFunction

function GetPlayerTextInput(string entrytype)
    ;disable for VR
    if !repository.isFO4VR
        if entryType == "playerResponseTextEntry" && _does_accept_player_input
            repository.GetTextInput(self as ScriptObject,"SetPlayerResponseTextInput","Enter Mantella text dialogue")
        elseif entryType == "gameEventEntry"
            repository.GetTextInput(self as ScriptObject, "SetGameEventTextInput","Enter Mantella a new game event log")
        elseif entryType == "playerResponseTextAndVisionEntry"
            repository.GetTextInput(self as ScriptObject, "SetPlayerResponseTextAndVisionInput","Enter Mantella text dialogue")
        endif
    endif
endFunction

Function SetPlayerResponseTextInput(string text)
    ;disable for VR
    if !repository.isFO4VR
        text = TopicInfoPatcher.StringRemoveWhiteSpace(text)
        if text == ""
            return
        Endif

        _PlayerTextInput=text
        if repository.allowFunctionCalling
            repository.resetFunctionInferenceNPCArrays()
            repository.UpdateFunctionInferenceNPCArrays(repository.GetFunctionInferenceActorList())
        endif
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
    if !repository.isFO4VR
        text = TopicInfoPatcher.StringRemoveWhiteSpace(text)
        if text == ""
            return
        Endif

        _PlayerTextInput = text
        repository.hasPendingVisionCheck=true
        StartTimer(0.3,_PlayerTextInputTimer)
    endif
EndFunction

Function SetGameEventTextInput(string text)
    ;disable for VR
    if !repository.isFO4VR
        text = TopicInfoPatcher.StringRemoveWhiteSpace(text)
        if text == ""
            return
        Endif
        AddIngameEvent(text)
    endif
EndFunction

    ;

function WaitForNpcToFinishSpeaking(Actor speaker, Actor lastNpcToSpeak, int handle)
    ; if this is the start of the conversation there is no need to wait, so skip this function entirely
    if lastNpcToSpeak != None
        ; if the current NPC did not speak last in a multi-NPC conversation, 
        ; wait for the last NPC to finish speaking to avoid interrupting
        if speaker != lastNpcToSpeak 
            WaitForSpecificNpcToFinishSpeaking(lastNpcToSpeak, handle)
        endIf
        ; wait for the current NPC to finish speaking before starting the next voiceline
        WaitForSpecificNpcToFinishSpeaking(speaker, handle)
    endIf
endFunction

function WaitForSpecificNpcToFinishSpeaking(Actor selectedNpc, int handle)
    selectedNpc.AddSpell(MantellaIsTalkingSpell, False)
   ; MantellaIsTalkingSpell.cast(selectedNpc as ObjectReference, selectedNpc as ObjectReference)
    float waitTime = 0.01
    float totalWaitTime = 0
    Utility.Wait(waitTime) ; allow time for _isTalking to be set
    while _isTalking == true ; wait until the NPC has finished speaking
        Utility.Wait(waitTime)
        totalWaitTime += waitTime
        if totalWaitTime > 10 ; note that this isn't really in seconds due to the overhead of the loop running
            Debug.Notification("NPC speaking too long, ending wait...")
            _isTalking = false
        endIf
    endWhile
    ;selectedNpc.DispelSpell(MantellaIsTalkingSpell)
    if handle>0
        var[] kargs = new Var[1]
        kargs[0]= _delayedHandle
        SendCustomEvent("DelayedCustomEventTrigger", kargs )
        UnregisterForCustomEvent(self, "DelayedCustomEventTrigger")
        selectedNpc.RemoveSpell(MantellaIsTalkingSpell)
    endif
 endFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       Action handler        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function RaiseActionEvent(Actor speaker, string lineToSpeak, string[] actions, int handle)
    if(!actions || actions.Length == 0)
        return ;dont send out an action event if there are no actions to act upon
    endIf

    int i = 0
    While i < actions.Length
        string extraAction = actions[i]
        if extraAction == mConsts.ACTION_NPC_INVENTORY
            RegisterForCustomEvent(self, "DelayedCustomEventTrigger")
            int delayedHandle = GenerateDelayedHandle()
            _delayedActionIdentifier[delayedHandle] = extraAction
            _delayedSpeaker[delayedHandle] = speaker
            _delayedlineToSpeak[delayedHandle] =lineToSpeak
            WaitForNpcToFinishSpeaking(speaker, _lastNpcToSpeak, delayedHandle)
        endif
        if extraAction != mConsts.ACTION_NPC_INVENTORY
            TriggerCorrectCustomEvent(extraAction, speaker, lineToSpeak, handle)
        endif
        i += 1
    EndWhile    
EndFunction

Event MantellaConversation.DelayedCustomEventTrigger (MantellaConversation akSender, var[] kargs)
    int handle = kargs[0] as int
    TriggerCorrectCustomEvent(_delayedActionIdentifier[handle], _delayedSpeaker[handle], _delayedlineToSpeak[handle],-1)
EndEvent

Function TriggerCorrectCustomEvent(string actionIdentifier, Actor speaker, string lineToSpeak, int handle)
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
        if repository.allowActionAggro 
            speaker.StartCombat(playerRef)
        endif
    ElseIf (actionIdentifier == mConsts.ACTION_NPC_FORGIVEN)
        SendCustomEvent("MantellaConversation_Action_mantella_npc_forgiven", kargs)
        speaker.StopCombat()
    ElseIf (actionIdentifier == mConsts.ACTION_NPC_FOLLOW)
        SendCustomEvent("MantellaConversation_Action_mantella_npc_follow", kargs)
        Faction CompanionFaction = Game.GetForm(0x000023C01) as Faction
        ;NPCs not yet available as companions have -1 faction rank
        if (repository.allowNPCsStayInPlace && repository.allowFollow && !speaker.IsinFaction(CompanionFaction)) || (speaker.GetFactionRank(CompanionFaction) < 0 && repository.allowFollow)
            Debug.Notification(speaker.GetDisplayName() + " is following")
            speaker.SetPlayerTeammate(true)
            speaker.EvaluatePackage()
        EndIf
    ElseIf (actionIdentifier == mConsts.ACTION_NPC_INVENTORY)
        if (speaker)
            if repository.allowActionInventory
                speaker.OpenInventory(true) 
            else
                Debug.Notification("Inventory action not enabled in the Mantella MCM.")
            endif
        endif
    ElseIf (actionIdentifier == mConsts.ACTION_NPC_MOVETO_NPC)
        debug.notification("Move to NPC action identifier recognized")
        string[] targetIDs= RetrieveTargetIDFunctionInferenceValues(handle)
        debug.notification("Target IDs array fetched "+targetIDs)
        actor targetNPC = repository.getActorFromArray(targetIDs[0],repository.MantellaFunctionInferenceActorList)
        if targetNPC
            RemoveAllParticipantsFromFaction(MantellaFunctionTargetFaction)
            CurrentFunctionTargetNPC=targetNPC
            If (CurrentFunctionTargetNPC==playerRef)
                speaker.SetPlayerTeammate(true)
                speaker.EvaluatePackage()
                repository.NPCAIPackageSelector=1
                debug.notification("Target NPC found, "+speaker.GetDisplayName()+" is following "+CurrentFunctionTargetNPC.GetDisplayName())
            else
                CurrentFunctionTargetNPC.AddToFaction(MantellaFunctionTargetFaction)
                repository.NPCAIPackageSelector=1
                debug.notification("Target NPC found, "+speaker.GetDisplayName()+" is moving towards "+CurrentFunctionTargetNPC.GetDisplayName())
            EndIf
            CauseReassignmentOfParticipantAlias()
            
        endif
    ElseIf (actionIdentifier == mConsts.ACTION_NPC_ATTACK_OTHER_NPC)
        debug.notification("Attack NPC action identifier recognized")
        string[] targetIDs= RetrieveTargetIDFunctionInferenceValues(handle)
        debug.notification("Target IDs array fetched "+targetIDs)
        actor targetNPC = repository.getActorFromArray(targetIDs[0],repository.MantellaFunctionInferenceActorList)
        if targetNPC
            repository.NPCAIPackageSelector=2
            RemoveAllParticipantsFromFaction(MantellaFunctionTargetFaction)
            CurrentFunctionTargetNPC=targetNPC
            CurrentFunctionTargetNPC.AddToFaction(MantellaFunctionTargetFaction)
            CauseReassignmentOfParticipantAlias()
            debug.notification("Target NPC found, "+speaker.GetDisplayName()+" is attacking "+CurrentFunctionTargetNPC.GetDisplayName())
        endif
    ElseIf (actionIdentifier == mConsts.ACTION_NPC_LOOT_ITEMS)
        repository.NPCAIItemToLootSelector=0
        if speaker.IsOverEncumbered()
            debug.notification(speaker.GetDisplayName()+" cannot scavenge for you because they are overemcumbered.") 
            return
        endif
        string[] item_type_to_loot= RetrieveTargetIDFunctionInferenceValues(handle)
        if item_type_to_loot[0] == "weapons"
            repository.NPCAIItemToLootSelector=1
            debug.notification(speaker.GetDisplayName()+" will scavenge weapons for you.")
        Elseif item_type_to_loot[0] == "armor"
            repository.NPCAIItemToLootSelector=2
            debug.notification(speaker.GetDisplayName()+" will scavenge armor for you.")
        Elseif item_type_to_loot[0] == "junk"
            repository.NPCAIItemToLootSelector=3
            debug.notification(speaker.GetDisplayName()+" will scavenge junk for you.")
        Elseif item_type_to_loot[0] == "consumables"
            repository.NPCAIItemToLootSelector=4
            debug.notification(speaker.GetDisplayName()+" will scavenge consumables for you.")
        Else
            debug.notification(speaker.GetDisplayName()+" will scavenge any items for you.")
        endif
        repository.NPCAIPackageSelector=3
        
        CauseReassignmentOfParticipantAlias()
        trackedPositionActor=speaker
        StoredActorPositionX = trackedPositionActor.getpositionX()
        StoredActorPositionY = trackedPositionActor.getpositionY()
        StoredActorPositionZ = trackedPositionActor.getpositionZ()
        StartTimer(4,RestartLootTimer)
    ElseIf (actionIdentifier == mConsts.ACTION_MAKE_NPC_WAIT)
        repository.NPCAIPackageSelector=0
        debug.notification(speaker.GetDisplayName()+" will wait")
        CauseReassignmentOfParticipantAlias()
    ElseIf (actionIdentifier == mConsts.ACTION_NPC_HEAL_PLAYER)
        repository.NPCAIPackageSelector=4
        repository.NPCAIItemToUseSelector=1
        debug.notification(speaker.GetDisplayName()+" will heal the player")
        CauseReassignmentOfParticipantAlias()
    endIf
endFunction

string[] Function RetrieveTargetIDFunctionInferenceValues(int handle)
    string[] targetIDs = F4SE_HTTP.getStringArray(handle, mConsts.FUNCTION_DATA_TARGET_IDS)
    return targetIDs
EndFunction

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

int Function GenerateDelayedHandle()
    _delayedHandle +=1
    return _delayedHandle
endfunction

function SetPlayerRef()
    playerRef = game.getplayer()
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
        MantellaConversationParticipantsQuest.Stop()
    EndIf
    if repository.allowNPCsStayInPlace || repository.allowFunctionCalling
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
            spokenTo = _lastNpcToSpeak
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
    F4SE_HTTP.setFloat(handleCustomContextValues, mConsts.KEY_CONTEXT_CUSTOMVALUES_PLAYERHEALTH, repository.PlayerRadFactoredHealth)
    F4SE_HTTP.setFloat(handleCustomContextValues, mConsts.KEY_CONTEXT_CUSTOMVALUES_PLAYERRAD, repository.PlayerRadiationPercent)
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
    if repository.allowFunctionCalling && repository.MantellaFunctionInferenceActorNamesList
        F4SE_HTTP.setString(handleCustomContextValues, mConsts.KEY_CONTEXT_CUSTOMVALUES_FUNCTIONS_NPCDISPLAYNAMES, repository.MantellaFunctionInferenceActorNamesList)
        F4SE_HTTP.setString(handleCustomContextValues, mConsts.KEY_CONTEXT_CUSTOMVALUES_FUNCTIONS_NPCDISTANCES, repository.MantellaFunctionInferenceActorDistanceList)
        F4SE_HTTP.setString(handleCustomContextValues, mConsts.KEY_CONTEXT_CUSTOMVALUES_FUNCTIONS_NPCIDS, repository.MantellaFunctionInferenceActorIDsList)
        F4SE_HTTP.setString(handleCustomContextValues, mConsts.KEY_CONTEXT_CUSTOMVALUES_FUNCTIONS_STIMPACKCOUNT, GetItemCountOfFirstNPC(StimpackItem))
    
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
;   LLM Function Calling functions   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

int function GetItemCountOfFirstNPC(Form akItem)
	int i = 0
    ;Will only return the stimpack count of the first non-player character in conversation
    While i < Participants.GetSize()
        if (Participants.GetAt(i) != playerRef)
            Actor currentactor = Participants.GetAt(i) as Actor
            return currentactor.GetItemCount (akItem)
        endif
        i += 1
    EndWhile
    return 0   
endFunction


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   SUP_F4SE & SUP_F4SEVR functions   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Functions to temporarly change some game settings
; to prevent various NPCs from interrupting conversations in progress
; Need to have the plugin save the values, as loading a game resets script variables,
; possibly losing the saved GameSettings
; All Game settings are reset when starting the game

; Save the game's original GameSettings before we modify them at conversation start
Function SaveSettings()
    if !SettingsSaved
;     TopicInfoPatcher.saveFloat("fAISocialTimerForConversationsMax")       ; Time to wait before NPC can trigger another conversation
;     TopicInfoPatcher.saveFloat("fAISocialTimerForConversationsMin")
;     TopicInfoPatcher.saveInt("iAISocialDistanceToTriggerEvent")
        TopicInfoPatcher.saveFloat("fAIGreetingTimer")
        TopicInfoPatcher.saveFloat("fAISocialchanceForConversation")      ; % of how likely a NPC will initiate a dialogue with another NPC
        TopicInfoPatcher.saveFloat("fAIMinGreetingDistance")        ; How close NPC must be to attempt greeting
        TopicInfoPatcher.saveFloat("fAIForceGreetingTimer")         ; How long NPC must wait before greeting again
        SettingsSaved = true;
    Endif
EndFunction

; Apply Mantella settings to stop NPCs talking
Function ApplySettings()
    if !SettingsSaved
        SaveSettings()
    Endif
    if !SettingsApplied
        Game.SetGameSettingFloat("fAIGreetingTimer", 600.0)
        Game.SetGameSettingFloat("fAISocialchanceForConversation", 1.0)        ; % of how likely a NPC will initiate a dialogue with another NPC
        Game.SetGameSettingFloat("fAIMinGreetingDistance", 1.0)        ; How close NPC must be to attempt greeting
        Game.SetGameSettingFloat("fAIForceGreetingTimer", 600.0)         ; How long NPC must wait before greeting again
        SettingsApplied = true
    EndIf
EndFunction

; Restore settings after conversation ends
Function RestoreSettings()
    if !SettingsSaved
        SaveSettings()
    Endif
    if SettingsApplied
        TopicInfoPatcher.restoreFloat("fAIGreetingTimer")
        TopicInfoPatcher.restoreFloat("fAISocialchanceForConversation")      ; % of how likely a NPC will initiate a dialogue with another NPC
        TopicInfoPatcher.restoreFloat("fAIMinGreetingDistance")        ; How close NPC must be to attempt greeting
        TopicInfoPatcher.restoreFloat("fAIForceGreetingTimer")         ; How long NPC must wait before greeting again
        SettingsApplied =  false
    EndIf
EndFunction


