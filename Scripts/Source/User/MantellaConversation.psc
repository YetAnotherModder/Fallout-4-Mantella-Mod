Scriptname MantellaConversation extends Quest hidden

Import F4SE
Import SUP_F4SE
Import Utility

Topic property MantellaDialogueLine auto
MantellaRepository property repository auto
MantellaConstants property mConsts auto

CustomEvent MantellaConversation_Action_mantella_reload_conversation
CustomEvent MantellaConversation_Action_mantella_end_conversation
CustomEvent MantellaConversation_Action_mantella_npc_offended
CustomEvent MantellaConversation_Action_mantella_npc_forgiven
CustomEvent MantellaConversation_Action_mantella_npc_follow

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;           Globals           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Form[] _actorsInConversation
String[] _ingameEvents
String[] _extraRequestActions
bool _does_accept_player_input = false

;VR exclusive part
;RequestCounter & acts like handle for F4SE_HTTP for output to Mantella Software
int RequestCounter
;JSON_Request will depend on RequestCounter to fetch the correct JSON name in the cache
String[] VR_JSON_Requests
;end VR exclusive part

event OnInit()
    _actorsInConversation = new Form[0]
    _ingameEvents = new String[0]
    _extraRequestActions = new String[0]
    RegisterForExternalEvent("OnHttpReplyReceived","OnHttpReplyReceived")
    RegisterForExternalEvent("OnHttpErrorReceived","OnHttpErrorReceived")
    ;VR exclusive part
    VR_JSON_Requests = new String[128]
    ;end VR exclusive part
    ;mConsts.EVENT_ACTIONS + mConsts.ACTION_RELOADCONVERSATION <- Does not work in Fallout4. Needs to be a raw string 
    ; RegisterForCustomEvent(self, "MantellaConversation_Action_mantella_reload_conversation")
    ; RegisterForCustomEvent(self, "MantellaConversation_Action_mantella_end_conversation")
endEvent

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;    Start new conversation   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function StartConversation(Actor[] actorsToStartConversationWith)
    if(actorsToStartConversationWith.Length > 2)
        Debug.Notification("Can not start conversation. Conversation is already running.")
        return
    endIf

    _actorsInConversation = new Form[0]
    _ingameEvents = new string[0]
    _extraRequestActions = new string[0]
    UpdateActorsArray(actorsToStartConversationWith)

    if(actorsToStartConversationWith.Length < 2)
        Debug.Notification("Not enough characters to start a conversation")
        return
    endIf
    int handle = F4SE_HTTP.createDictionary()
    ;VR exclusive part
    VR_OnJsonReplyReceived("mantella_json_output.json")
    int VRhandle = RequestCounter
    RequestCounter+=1
    VR_JSON_Requests[VRhandle]="mantella_json_start_conversation" 
    if JSONIsFileCached(VR_JSON_Requests[VRhandle]) ;Checks if JSON already exist and clears JSON before using it
        SUP_F4SE.JSONEraseKey(VR_JSON_Requests[VRhandle], "", 1) 
    endif
    SUP_F4SE.JSONCacheFile(VR_JSON_Requests[VRhandle], 1)
    ;end VR exclusive part
    F4SE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE, mConsts.KEY_REQUESTTYPE_STARTCONVERSATION)
    ;VR exclusive part
    SUP_F4SE.JSONSetValueString(VR_JSON_Requests[VRhandle], mConsts.KEY_REQUESTTYPE, mConsts.KEY_REQUESTTYPE_STARTCONVERSATION, 1)

    ;end VR exclusive part
    AddCurrentActorsAndContext(handle)
    ;VR exclusive part
    VR_AddCurrentActorsAndContext(VRhandle)
    VR_CloseJsonArray(VR_JSON_Requests)
    ;end VR exclusive part
    F4SE_HTTP.sendLocalhostHttpRequest(handle, mConsts.HTTP_PORT, mConsts.HTTP_ROUTE_MAIN)
    string address = "http://localhost:" + mConsts.HTTP_PORT + "/" + mConsts.HTTP_ROUTE_MAIN
    Debug.Notification("Sent StartConversation http request to " + address)  
endFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;    Continue conversation    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function AddActorsToConversation(Actor[] actorsToAdd)
    UpdateActorsArray(actorsToAdd)    
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

;VR exclusive part 

function VR_OnJsonReplyReceived(string JSONFilename)
    int debugcheck = SUP_F4SE.JSONCacheFile(JSONFilename, 0)
    if debugcheck>0
        JSONValue replytype = SUP_F4SE.JSONGetValue(JSONFilename, mConsts.KEY_REPLYTYPE, 1)
        if (replytype.JSONSuccess == 3) && (replyType.JSONsValue != "error")
            ;debug.notification("Read Success, continuing conversation")
            VR_ContinueConversation(JSONFilename)
        Elseif (replytype.JSONSuccess == 3) 
            JSONValue errorMessage = SUP_F4SE.JSONGetValue(JSONFilename, "mantella_message",1)
            if (replytype.JSONSuccess == 3)
                Debug.Notification(errorMessage.JSONsValue)
            Else
                Debug.Notification("Error: Could not retrieve error message")
            endif
            debug.notification("Read fail, ending conversation")
            ;CleanupConversation()
        Else
            Debug.Notification("Couldn't read JSON Reply type")
        EndIf
    Else
        Debug.Notification("Error can't read JSON Mantella output, SUP_F4SE error code : "+VR_JSONdebugInterpreter(debugcheck))
        Debug.trace("Error can't read JSON Mantella output, SUP_F4SE error code : "+VR_JSONdebugInterpreter(debugcheck))
    endif
    ;added this part to have a way to check if papyrus processed the message yet or not
    SUP_F4SE.JSONSetValueFloat(JSONFilename, "mantella_papyrus_processed",1, 1, 1)
endFunction
;end VR exclusive part


string function VR_JSONGetString(string JSONFilename, string JSONKey, string errormessage )
    JSONValue JSONString = SUP_F4SE.JSONGetValue(JSONFilename, JSONKey, 1)
    if (JSONString.JSONSuccess == 3)
        return JSONString.JSONsValue
    else
        return errormessage
    endif
endfunction 


string function VR_JSONdebugInterpreter(int debugcode)
    ;match debug code with array for errors by adding 14 to it
    debugcode=(debugcode+14)
    string[] debugMessageArray = new string[15]
    debugMessageArray[0] = "-14 : Parsed JSON is not structured : tried to parse JSON object via string and it's not valid"
    debugMessageArray[1] = "-13 : No Save Path : JSON file is missing save path"
    debugMessageArray[2] = "-12 : Can't write to file : data can't be written to specified file"
    debugMessageArray[3] = "-11 : Pos in Array out of range : tried to erase or access value in array which is out of range(i.e. request pos is 5 while array only has 4 elements)"
    debugMessageArray[4] = "-10 : Not an array : tried to append value to existing key which is not an array"
    debugMessageArray[5] = "Not used"
    debugMessageArray[6] = "Not used"
    debugMessageArray[7] = "Not used"
    debugMessageArray[8] = "-6 : WrongFileExtension : tried to open other file with extenstion other than '.json'"
    debugMessageArray[9] = "-5 : WrongDirectory :  tried to access directory outside of game folder"
    debugMessageArray[10] = "-4 : CantOpen : File can't be opened or doesn't exist;"
    debugMessageArray[11] = "-3 : NotStructured : JSON file is not structured"
    debugMessageArray[12] = "-2 : KeyNotFound : Specified key is not found in JSON file"
    debugMessageArray[13] = "-1 : SuccessOtherType : Value of JSON key is not supported type(binary or discarded types)"
    debugMessageArray[14] = "0 : SuccessNULL : File was read sucessfully and the value is NULL"

    return debugMessageArray[debugcode] as string
endfunction

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
            sendRequestForVoiceTranscribe()
        Else
            Debug.Notification("Awaiting player text input...")
            _does_accept_player_input = True
        EndIf
    elseIf (nextAction == mConsts.KEY_REQUESTTYPE_TTS)
        string transcribe = F4SE_HTTP.getString(handle, mConsts.KEY_TRANSCRIBE, "*Complete gibberish*")
        sendRequestForPlayerInput(transcribe)
    elseIf(nextAction == mConsts.KEY_REPLYTYPE_ENDCONVERSATION)
        CleanupConversation()
    endIf
endFunction


function VR_ContinueConversation(string JSONFilename)
    string nextAction = VR_JSONGetString(JSONFilename, mConsts.KEY_REPLYTYPE,"Error: Did not receive reply type" )
    if(nextAction == mConsts.KEY_REPLYTTYPE_STARTCONVERSATIONCOMPLETED)
        ;RequestContinueConversation()
    elseIf(nextAction == mConsts.KEY_REPLYTYPE_NPCTALK)
        ;CONTINUE FROM HERE
        JSONValue JSONstruct = JSONGetValue(JSONFilename, mConsts.KEY_REPLYTYPE_NPCTALK, 1)
        debug.messagebox(JSONstruct.JSONsValue)
        JSONValue[] JSONarray = JSONGetValueArray(JSONFilename, mConsts.KEY_REPLYTYPE_NPCTALK, 1)
        debug.messagebox(JSONarray as string)
        ;VR_ProcessNpcSpeak(JSONFilename) ;NEED TO ADD FUNCTION
        ;VR_RequestContinueConversation() ;NEED TO ADD FUNCTION
    endif
endFunction




function RequestContinueConversation()
    int handle = F4SE_HTTP.createDictionary()
    F4SE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE, mConsts.KEY_REQUESTTYPE_CONTINUECONVERSATION)
    AddCurrentActorsAndContext(handle)
    if(_extraRequestActions && _extraRequestActions.Length > 0)
        Debug.Notification("_extraRequestActions contains items. Sending them along with continue!")
        F4SE_HTTP.setStringArray(handle, mConsts.KEY_REQUEST_EXTRA_ACTIONS, _extraRequestActions)
        ClearExtraRequestAction()
        Debug.Notification("_extraRequestActions got cleared. Remaining items: " + _extraRequestActions.Length)
    endif
    F4SE_HTTP.sendLocalhostHttpRequest(handle, mConsts.HTTP_PORT, mConsts.HTTP_ROUTE_MAIN)
endFunction

function ProcessNpcSpeak(int handle)
    string speakerName = F4SE_HTTP.getString(handle, mConsts.KEY_ACTOR_SPEAKER, "Error: No speaker transmitted for action 'NPC talk'")
    ;Debug.Notification("Transmitted speaker name: "+ speakerName)
    Actor speaker = GetActorInConversation(speakerName)
    ;Debug.Notification("Chosen Actor: "+ speaker.GetDisplayName())
    if speaker != none
        string lineToSpeak = F4SE_HTTP.getString(handle, mConsts.KEY_ACTOR_LINETOSPEAK, "Error: No line transmitted for actor to speak")
        float duration = F4SE_HTTP.getFloat(handle, mConsts.KEY_ACTOR_DURATION, 0)
        string[] actions = F4SE_HTTP.getStringArray(handle, mConsts.KEY_ACTOR_ACTIONS)        
        RaiseActionEvent(speaker, lineToSpeak, actions)
        NpcSpeak(speaker, lineToSpeak, Game.GetPlayer(), duration)
    endIf
endFunction

function NpcSpeak(Actor actorSpeaking, string lineToSay, Actor actorToSpekTo, float duration)
    ; MantellaSubtitles.SetInjectTopicAndSubtitleForSpeaker(actorSpeaking, MantellaDialogueLine, lineToSay)
    actorSpeaking.Say(MantellaDialogueLine, abSpeakInPlayersHead=false)
    actorSpeaking.SetLookAt(actorToSpekTo)
    float durationAdjusted = duration - 0.5
    if(durationAdjusted < 0)
        durationAdjusted = 0
    endIf
    Utility.Wait(durationAdjusted)
endfunction

Actor function GetActorInConversation(string actorName)      
    int i = 0
    While i < _actorsInConversation.Length
        Actor currentActor = _actorsInConversation[i] as Actor
        if currentActor.GetDisplayName() == actorName
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
    int handle = F4SE_HTTP.createDictionary()
    F4SE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE,mConsts.KEY_REQUESTTYPE_ENDCONVERSATION)
    F4SE_HTTP.sendLocalhostHttpRequest(handle, mConsts.HTTP_PORT, mConsts.HTTP_ROUTE_MAIN)
EndFunction

Function CleanupConversation()
    _does_accept_player_input = false
    F4SE_HTTP.clearAllDictionaries()
    Debug.Notification("Conversation has ended!")  
    Stop()
EndFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Handle player speaking    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function sendRequestForPlayerInput(string playerInput)
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
endFunction

function sendRequestForVoiceTranscribe()
    int handle = F4SE_HTTP.createDictionary()
    F4SE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE, mConsts.KEY_REQUESTTYPE_TTS)
    string[] namesInConversation = new string[_actorsInConversation.Length]
    int i = 0
    While i < _actorsInConversation.Length
        namesInConversation[i] = (_actorsInConversation[i] as Actor).GetDisplayName()
        i += 1
    EndWhile
    F4SE_HTTP.setStringArray(handle, mConsts.KEY_INPUT_NAMESINCONVERSATION, namesInConversation)
    F4SE_HTTP.sendLocalhostHttpRequest(handle, mConsts.HTTP_PORT, mConsts.HTTP_ROUTE_STT)
endFunction

function GetPlayerTextInput()
    if(!_does_accept_player_input)
        return
    endif

    TIM:TIM.Open(1,"Enter Mantella text dialogue","", 2, 250)
    RegisterForExternalEvent("TIM::Accept","SetTextInput")
    RegisterForExternalEvent("TIM::Cancel","NoTextInput")    
endFunction

Function SetTextInput(string text)
    ;Debug.notification("This text input was entered "+ text)
    UnRegisterForExternalEvent("TIM::Accept")
    UnRegisterForExternalEvent("TIM::Cancel")
    sendRequestForPlayerInput(text)
    _does_accept_player_input = False
EndFunction
    ;
Function NoTextInput(string text)
    ;Debug.notification("Text input cancelled")
    UnRegisterForExternalEvent("TIM::Accept")
    UnRegisterForExternalEvent("TIM::Cancel")
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
        Debug.Notification("Recieved action " + extraAction + ". Sending out event!")
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
    ElseIf (actionIdentifier == mConsts.ACTION_NPC_OFFENDED)
        SendCustomEvent("MantellaConversation_Action_mantella_npc_offended", kargs)
    ElseIf (actionIdentifier == mConsts.ACTION_NPC_FORGIVEN)
        SendCustomEvent("MantellaConversation_Action_mantella_npc_forgiven", kargs)
    ElseIf (actionIdentifier == mConsts.ACTION_NPC_FOLLOW)
        SendCustomEvent("MantellaConversation_Action_mantella_npc_follow", kargs)
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
    Debug.Notification("OnReloadConversationActionReceived triggered")
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

bool Function IsPlayerInConversation()
    int i = 0
    While i < _actorsInConversation.Length
        if (_actorsInConversation[i] == Game.GetPlayer())
            return true
        endif
        i += 1
    EndWhile
    return false    
EndFunction

Function UpdateActorsArray(Actor[] actorsToUpdate)
    int i = 0    
    While i < actorsToUpdate.Length
        int pos = _actorsInConversation.Find(actorsToUpdate[i])
        if(pos < 0)
            _actorsInConversation.Add(actorsToUpdate[i])
        endIf
        i += 1
    EndWhile
EndFunction

int Function CountActorsInConversation()
    return _actorsInConversation.Length
EndFunction

Actor Function GetActorInConversationByIndex(int indexOfActor) 
    If (indexOfActor >= 0 && indexOfActor < _actorsInConversation.Length)
        return _actorsInConversation[indexOfActor] as Actor
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

;VR exclusive part
Function VR_AddCurrentActorsAndContext(int handleToAddTo)
    ;Add Actors
    int[] handlesNpcs = VR_BuildNpcsInConversationArray()
    VR_SetNestedDictionariesArray(handleToAddTo, mConsts.KEY_ACTORS, handlesNpcs)

    int handleContext = VR_BuildContext()
    VR_SetNestedDictionary(handleToAddTo, mConsts.KEY_CONTEXT, handleContext)
EndFunction
;end VR exclusive part

;VR exclusive part
int Function VR_createDictionary(string JSONCacheName)
    int VRhandle = RequestCounter
    RequestCounter+=1
    VR_JSON_Requests[VRhandle]=JSONCacheName+"_"+VRhandle
    if JSONIsFileCached(VR_JSON_Requests[VRhandle]) ;Checks if JSON already exist and clears JSON before using it
        SUP_F4SE.JSONEraseKey(VR_JSON_Requests[VRhandle], "", 1) 
    endif
    SUP_F4SE.JSONCacheFile(VR_JSON_Requests[VRhandle], 1)
    return VRhandle
Endfunction
;end VR exclusive part

;VR exclusive part
;This remove all the caches JSON contained in the array and save them to file if they need to be read by Mantella Software (e.g. being "mantella_json_start_conversation")
int Function VR_CloseJsonArray(String[] JSONArrayName)
    int i = 0
    While i < JSONArrayName.Length
        ;TO UPDATE : REMOVE COMMENTED LINE WHEN FINISHED TESTING
        if JSONArrayName[i]
            ;if JSONArrayName[i]=="mantella_json_start_conversation"
            SUP_F4SE.JSONCloseFile(JSONArrayName[i], 1, JSONArrayName[i]+".json")
            ;endif
        endif
        i += 1
    EndWhile
    RequestCounter=0
Endfunction
;end VR exclusive part

;VR exclusive part
Function VR_SetNestedDictionariesArray(int JSON_handle,String ArrayKey,int[] ArrayToSet)
    int i = 0
    int CurrentArrayHandle=0
    string currentArrayString
    string currentJSONArrayName
    int debugcheck
    While i < ArrayToSet.Length
        CurrentArrayHandle = ArrayToSet[i]   
        currentJSONArrayName = VR_JSON_Requests[CurrentArrayHandle]
        currentArrayString=SUP_F4SE.JSONToString(currentJSONArrayName)
        debugcheck= SUP_F4SE.JSONAppendValueString(VR_JSON_Requests[JSON_handle], ArrayKey+"\\nestedobject",currentArrayString , 1,1) 
        if debugcheck<1
            Debug.trace("VR_SetNestedDictionariesArray "+currentJSONArrayName+" failed to build. Error code : "+debugcheck)
        endif
        i += 1
    EndWhile
Endfunction
;end VR exclusive part

;VR exclusive part
Function VR_SetNestedDictionary(int JSON_handle,String JSONKey,int JSONtoSetHandle)
    int debugcheck
    string JSONName = VR_JSON_Requests[JSONtoSetHandle]
    string JSONString=SUP_F4SE.JSONToString(JSONName)
    debugcheck= SUP_F4SE.JSONAppendValueString(VR_JSON_Requests[JSON_handle], JSONKey+"\\NestedObject",JSONString , 1,1) 
    if debugcheck<1
        Debug.trace("VR_SetNestedDictionary "+JSONName+" failed to build. Error code : "+debugcheck)
    endif
Endfunction
;end VR exclusive part

int[] function BuildNpcsInConversationArray()
    int[] actorHandles =  new int[_actorsInConversation.Length]
    int i = 0
    While i < _actorsInConversation.Length
        actorHandles[i] = buildActorSetting(_actorsInConversation[i] as Actor)
        i += 1
    EndWhile
    return actorHandles
endFunction

;VR exclusive part
int[] function VR_BuildNpcsInConversationArray()
    int[] actorHandles =  new int[_actorsInConversation.Length]
    int i = 0
    While i < _actorsInConversation.Length
        actorHandles[i] = VR_BuildActorSetting(_actorsInConversation[i] as Actor)
        i += 1
    EndWhile
    return actorHandles
endFunction
;end VR exclusive part

int function buildActorSetting(Actor actorToBuild)    
    int handle = F4SE_HTTP.createDictionary()
    F4SE_HTTP.setInt(handle, mConsts.KEY_ACTOR_ID, (actorToBuild.getactorbase() as form).getformid())
    F4SE_HTTP.setString(handle, mConsts.KEY_ACTOR_NAME, actorToBuild.GetDisplayName())
    F4SE_HTTP.setBool(handle, mConsts.KEY_ACTOR_ISPLAYER, actorToBuild == game.getplayer())
    F4SE_HTTP.setInt(handle, mConsts.KEY_ACTOR_GENDER, actorToBuild.getleveledactorbase().getsex())
    F4SE_HTTP.setString(handle, mConsts.KEY_ACTOR_RACE, actorToBuild.getrace())
    F4SE_HTTP.setInt(handle, mConsts.KEY_ACTOR_RELATIONSHIPRANK, actorToBuild.getrelationshiprank(game.getplayer()))
    F4SE_HTTP.setString(handle, mConsts.KEY_ACTOR_VOICETYPE, actorToBuild.GetVoiceType())
    F4SE_HTTP.setBool(handle, mConsts.KEY_ACTOR_ISINCOMBAT, actorToBuild.IsInCombat())    
    F4SE_HTTP.setBool(handle, mConsts.KEY_ACTOR_ISENEMY, actorToBuild.getcombattarget() == game.GetPlayer())
    int customValuesHandle = BuildCustomActorValues(actorToBuild)
    F4SE_HTTP.setNestedDictionary(handle, mConsts.KEY_ACTOR_CUSTOMVALUES, customValuesHandle)  
    return handle
endFunction

    ;VR exclusive part
int function VR_BuildActorSetting(Actor actorToBuild)   
    int handle = VR_createDictionary("_mantella_json_actor_settings")
    SUP_F4SE.JSONSetValueFloat(VR_JSON_Requests[handle], mConsts.KEY_ACTOR_ID,(actorToBuild.getactorbase() as form).getformid(),1) 
    SUP_F4SE.JSONSetValueString(VR_JSON_Requests[handle], mConsts.KEY_ACTOR_NAME, actorToBuild.GetDisplayName(),1)
    SUP_F4SE.JSONSetValueFloat(VR_JSON_Requests[handle], mConsts.KEY_ACTOR_ISPLAYER, (actorToBuild == game.getplayer()) as float,1,1) ;is bool so added extra 1 parameter at the end
    SUP_F4SE.JSONSetValueFloat(VR_JSON_Requests[handle], mConsts.KEY_ACTOR_GENDER, actorToBuild.getleveledactorbase().getsex(),1)
    SUP_F4SE.JSONSetValueString(VR_JSON_Requests[handle], mConsts.KEY_ACTOR_RACE, actorToBuild.getrace(),1)
    SUP_F4SE.JSONSetValueFloat(VR_JSON_Requests[handle], mConsts.KEY_ACTOR_RELATIONSHIPRANK, actorToBuild.getrelationshiprank(game.getplayer()),1)
    SUP_F4SE.JSONSetValueString(VR_JSON_Requests[handle], mConsts.KEY_ACTOR_VOICETYPE, actorToBuild.GetVoiceType(),1)
    SUP_F4SE.JSONSetValueFloat(VR_JSON_Requests[handle], mConsts.KEY_ACTOR_ISINCOMBAT, actorToBuild.IsInCombat() as float,1,1)     ;is bool so added extra 1 parameter at the end
    SUP_F4SE.JSONSetValueFloat(VR_JSON_Requests[handle], mConsts.KEY_ACTOR_ISENEMY, (actorToBuild.getcombattarget() == game.GetPlayer()) as float,1,1) ;is bool so added extra 1 parameter at the end
    int customValuesHandle = VR_BuildCustomActorValues(actorToBuild)
    VR_SetNestedDictionary(handle, mConsts.KEY_ACTOR_CUSTOMVALUES, customValuesHandle)
    return handle
endFunction
    ;end VR exclusive part

int Function BuildCustomActorValues(Actor actorToBuildCustomValuesFor)
    int handleCustomActorValues = F4SE_HTTP.createDictionary()
    F4SE_HTTP.setFloat(handleCustomActorValues, mConsts.KEY_ACTOR_CUSTOMVALUES_POSX, actorToBuildCustomValuesFor.getpositionX())
    F4SE_HTTP.setFloat(handleCustomActorValues, mConsts.KEY_ACTOR_CUSTOMVALUES_POSY, actorToBuildCustomValuesFor.getpositionY())
    return handleCustomActorValues
EndFunction

;VR exclusive part
int Function VR_BuildCustomActorValues(Actor actorToBuildCustomValuesFor)
    int handleCustomActorValues = VR_createDictionary("_mantella_json_custom_actor_values")
    SUP_F4SE.JSONSetValueFloat(VR_JSON_Requests[handleCustomActorValues], mConsts.KEY_ACTOR_CUSTOMVALUES_POSX, actorToBuildCustomValuesFor.getpositionX(),1)
    SUP_F4SE.JSONSetValueFloat(VR_JSON_Requests[handleCustomActorValues], mConsts.KEY_ACTOR_CUSTOMVALUES_POSY, actorToBuildCustomValuesFor.getpositionY(),1)
    return handleCustomActorValues
EndFunction
;end VR exclusive part

int function BuildContext()
    int handle = F4SE_HTTP.createDictionary()
    String currLoc = ""
    form currentLocation = game.getplayer().GetCurrentLocation() as Form
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

;VR exclusive part
int function VR_BuildContext()
    int handle = VR_createDictionary("_mantella_json_context")
    String currLoc = ""
    int debugcheck
    form currentLocation = game.getplayer().GetCurrentLocation() as Form
    if currentLocation
        currLoc = currentLocation.getName()
    Else
        currLoc = "Boston area"
    endIf
    SUP_F4SE.JSONSetValueString(VR_JSON_Requests[handle], mConsts.KEY_CONTEXT_LOCATION, currLoc,1)
    SUP_F4SE.JSONSetValueFloat(VR_JSON_Requests[handle], mConsts.KEY_CONTEXT_TIME, GetCurrentHourOfDay(),1)
    debugcheck= SUP_F4SE.JSONAppendValueString(VR_JSON_Requests[handle], mConsts.KEY_CONTEXT_INGAMEEVENTS+"\\NestedObject",_ingameEvents , 1,1) 
    if debugcheck<1
        Debug.trace("JSONAppendValueString "+VR_JSON_Requests[handle]+" failed to build. Error code : "+debugcheck)
    endif
    int customValuesHandle = VR_BuildCustomContextValues()
    VR_SetNestedDictionary(handle, mConsts.KEY_CONTEXT_CUSTOMVALUES, customValuesHandle)
    return handle
endFunction
;end VR exclusive part

int Function BuildCustomContextValues()
    int handleCustomContextValues = F4SE_HTTP.createDictionary()
    Actor player = game.getplayer()  
    F4SE_HTTP.setFloat(handleCustomContextValues, mConsts.KEY_CONTEXT_CUSTOMVALUES_PLAYERPOSX, player.getpositionX())
    F4SE_HTTP.setFloat(handleCustomContextValues, mConsts.KEY_CONTEXT_CUSTOMVALUES_PLAYERPOSY, player.getpositionY())
    F4SE_HTTP.setFloat(handleCustomContextValues, mConsts.KEY_CONTEXT_CUSTOMVALUES_PLAYERROT, player.GetAngleZ())
    return handleCustomContextValues
EndFunction

;VR exclusive part
int Function VR_BuildCustomContextValues()
    int handleCustomContextValues = VR_createDictionary("_mantella_json_custom_context_values")
    Actor player = game.getplayer()  
    SUP_F4SE.JSONSetValueFloat(VR_JSON_Requests[handleCustomContextValues], mConsts.KEY_CONTEXT_CUSTOMVALUES_PLAYERPOSX, player.getpositionX(),1)
    SUP_F4SE.JSONSetValueFloat(VR_JSON_Requests[handleCustomContextValues], mConsts.KEY_CONTEXT_CUSTOMVALUES_PLAYERPOSY, player.getpositionY(),1)
    SUP_F4SE.JSONSetValueFloat(VR_JSON_Requests[handleCustomContextValues], mConsts.KEY_CONTEXT_CUSTOMVALUES_PLAYERROT, player.GetAngleZ(),1)
    return handleCustomContextValues
EndFunction
;end VR exclusive part

int function GetCurrentHourOfDay()
	float Time = Utility.GetCurrentGameTime()
	Time -= Math.Floor(Time) ; Remove "previous in-game days passed" bit
	Time *= 24 ; Convert from fraction of a day to number of hours
	int Hour = Math.Floor(Time) ; Get whole hour
	return Hour
endFunction