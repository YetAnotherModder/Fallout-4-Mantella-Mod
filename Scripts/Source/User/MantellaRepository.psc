Scriptname MantellaRepository extends Quest Conditional
;Import SUP_F4SE

;keycode properties
int property textkeycode auto
int property textAndVisionKeycode auto
int property MantellaVisionKeycode auto
int property gameEventkeycode auto
int property startConversationkeycode auto

; string property textinput auto
int property MenuEventSelector auto
MantellaConversation property conversation auto
MantellaConstants property ConstantsScript auto

;endFlagMantellaConversationOne exists to prevent conversation loops from getting stuck on NPCs if Mantella crashes or interactions gets out of sync
bool property endFlagMantellaConversationOne auto
string property currentFO4version auto
bool property isFO4VR auto Conditional
bool property microphoneEnabled auto
bool property radiantEnabled auto
bool property notificationsSubtitlesEnabled auto
float property radiantDistance auto
float property radiantFrequency auto

;vision parameters
bool property allowVision auto
bool property hasPendingVisionCheck auto
string property visionResolution auto
int property visionResize auto Conditional


bool property allowAggro auto
bool property allowNPCsStayInPlace auto Conditional
bool property allowFollow auto
bool property allowCrosshairTracking auto
Spell property MantellaSpell auto
Perk property ActivatePerk auto
;variables below for Player game event tracking
bool property playerTrackingOnItemAdded auto
bool property playerTrackingOnItemRemoved auto
bool property playerTrackingOnHit auto
bool property playerTrackingOnLocationChange auto
bool property playerTrackingOnObjectEquipped auto
bool property playerTrackingOnObjectUnequipped auto
bool property playerTrackingOnSit auto
bool property playerTrackingOnGetUp auto
bool property playerTrackingFireWeapon auto
bool property playerTrackingRadiationDamage auto
bool property playerTrackingSleep auto
bool property playerTrackingCripple auto
bool property playerTrackingHealTeammate auto


;variables below for Mantella Target tracking
bool property targetTrackingItemAdded auto 
bool property targetTrackingItemRemoved auto
bool property targetTrackingOnHit auto
bool property targetTrackingOnCombatStateChanged auto
bool property targetTrackingOnObjectEquipped auto
bool property targetTrackingOnObjectUnequipped auto
bool property targetTrackingOnSit auto
bool property targetTrackingOnGetUp auto
bool property targetTrackingCompleteCommands auto
bool property targetTrackingGiveCommands auto


;variables below are to prevent game listener events from firing too often
bool property EventFireWeaponSpamBlocker auto
bool property EventRadiationDamageSpamBlocker auto
int property WeaponFiredCount auto


ActorValue property HealthAV auto
ActorValue property RadsAV auto
float radiationToHealthRatio = 0.229
Actor property CrosshairActor auto
int CleanupconversationTimer=2

;Callback variables for SimpleTextField
ScriptObject CBscript =  none
string CBfunction


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Game management functions and events   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Event OnInit()
    reinitializeVariables()    
EndEvent


Function ResetEventSpamBlockers()
    EventFireWeaponSpamBlocker=false
    WeaponFiredCount=0
    EventRadiationDamageSpamBlocker=false
Endfunction

Function reloadKeys()
    ;called at player load and when reinitializing variables
    setHotkey(textkeycode, "Dialogue")
    setHotkey(gameEventkeycode, "GameEvent")
    setHotkey(startConversationkeycode,"StartConversation")
    setHotkey(textAndVisionKeycode,"DialogueAndVision")
    setHotkey(MantellaVisionKeycode,"MantellaVision")
    RegisterForOnCrosshairRefChange()							; Re-enable if disabled
    conversation.RestoreSettings()                              ; Make sure Game settings are restored after a load
Endfunction


Function StopConversations()
    If (conversation.IsRunning())
        conversation.EndConversation()
        StartTimer(5,CleanupconversationTimer)              ;Start a timer to make second hard reset if conversation is still running after
        conversation.conversationIsEnding = false
    EndIf
    ; endFlagMantellaConversationOne = True
    ; SUP_F4SE.WriteStringToFile("_mantella_end_conversation.txt", "True", 0)
    ; Utility.Wait(0.5)
    ; endFlagMantellaConversationOne = False
    ; SUP_F4SE.WriteStringToFile("_mantella_end_conversation.txt", "False", 0)
EndFunction

Event Ontimer( int TimerID)
    if TimerID==CleanupconversationTimer 
        ;debug.notification("checking if conversation is still running")
        if conversation.IsRunning() ;attempts to make a hard reset of the conversation if it's still going on for some reason
             ;previous conversation detected, forcing conversation to end.
             debug.notification("Previous conversation detected after request to end : Cleaning up.")
             Conversation.CleanupConversation()
         endif
     endif
 EndEvent


Function reinitializeVariables()
    ;change the below this is for debug only
    textkeycode=72
    gameEventkeycode=89
    startConversationkeycode=72
    reloadKeys()
    radiantEnabled = true
    radiantDistance = 20
    radiantFrequency = 10
    notificationsSubtitlesEnabled = true
    allowVision = false
    visionResolution="auto"
    visionResize=1024
    allowAggro = false
    allowFollow = false
    allowNPCsStayInPlace = true
    MenuEventSelector=0
    microphoneEnabled = true
    ConstantsScript.HTTP_PORT = 4999
    togglePlayerEventTracking(true)
    toggleTargetEventTracking(true)
    RegisterForOnCrosshairRefChange()
    Actor PlayerRef = Game.GetPlayer()
    If !(PlayerRef.HasPerk(ActivatePerk))
        PlayerRef.AddPerk(ActivatePerk, False)
    Endif
    conversation.conversationIsEnding = false
EndFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Toggling and setting functions   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function togglePlayerEventTracking(bool bswitch)
    ;Player tracking variables below
    if bswitch
        Debug.notification("Player event tracking is now ON")
    else
        Debug.notification("Player event tracking is now OFF")
    endif
    playerTrackingOnItemAdded = bswitch
    playerTrackingOnItemRemoved = bswitch
    playerTrackingOnHit = bswitch
    playerTrackingOnLocationChange = bswitch
    playerTrackingOnObjectEquipped = bswitch
    playerTrackingOnObjectUnequipped = bswitch
    playerTrackingOnSit = bswitch
    playerTrackingOnGetUp = bswitch
    playerTrackingFireWeapon = bswitch
    playerTrackingRadiationDamage=bswitch
    playerTrackingSleep = bswitch
    playerTrackingCripple = bswitch
    playerTrackingHealTeammate = bswitch
EndFunction

Function toggleTargetEventTracking(bool bswitch)
    ;Target tracking variables below
    if bswitch
        Debug.notification("NPC in conversation  event tracking is now ON")
    else
        Debug.notification("NPCs in conversation event tracking is now OFF")
    endif
    targetTrackingItemAdded = bswitch 
    targetTrackingItemRemoved = bswitch
    targetTrackingOnHit = bswitch
    targetTrackingOnCombatStateChanged = bswitch
    targetTrackingOnObjectEquipped = bswitch
    targetTrackingOnObjectUnequipped = bswitch
    targetTrackingOnSit = bswitch
    targetTrackingOnGetUp = bswitch
    targetTrackingCompleteCommands = bswitch
    targetTrackingGiveCommands = bswitch
EndFunction

Function toggleNotificationSubtitles(bool bswitch)
    notificationsSubtitlesEnabled = bswitch
    if bswitch
        Debug.notification("Subtitles enabled")
    else
        Debug.notification("Subtitles disabled")
    endif
EndFunction

Function toggleAllowAggro(bool bswitch)
    allowAggro = bswitch
    if bswitch
        Debug.notification("NPC are now allowed to aggro")
    else
        Debug.notification("NPC are not allowed to aggro")
    endif
EndFunction

Function toggleAllowFollow(bool bswitch)
    allowFollow = bswitch
EndFunction

Function toggleAllowNPCsStayInPlace(bool bswitch)
    allowNPCsStayInPlace = bswitch
EndFunction

Function togglemicrophoneEnabled(bool bswitch)
    microphoneEnabled = bswitch
    if bswitch
        Debug.notification("Microphone is now ON")
    else
        Debug.notification("Microphone is now OFF")
    endif
EndFunction

Function toggleAllowVision(bool bswitch)
    allowVision = bswitch
    if bswitch
        Debug.notification("Vision analysis is now ON")
    else
        Debug.notification("Vision analysis is now OFF")
    endif
EndFunction

Function ToggleActivatePerk()
    Actor PlayerRef = Game.GetPlayer()
    If (PlayerRef.HasPerk(ActivatePerk))
		PlayerRef.RemovePerk(ActivatePerk)
        Debug.notification("Alt conversation activation option is now ON")
	Else
        PlayerRef.AddPerk(ActivatePerk, False)
        Debug.notification("Alt conversation activation option is now OFF")
	EndIf
EndFunction

Function SetVisionResolution(string resolution)
    visionResolution = resolution
    Debug.notification("Vision resolution is now "+resolution)
EndFunction

Function SetVisionResize(int resizeResolution)
    visionResize = resizeResolution
    Debug.notification("Vision images will now be resized to "+visionResize)
EndFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Pipboy Management    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function listMenuState(String aMenu)
    if aMenu=="NPC_Actions"
        if allowAggro==false
            debug.notification("NPC aggro is OFF")
        else
            debug.notification("NPC aggro is ON")
        endif
        if allowFollow==false
            debug.notification("NPC follow is OFF")
        else
            debug.notification("NPC follow is ON")
        endif
    elseif aMenu=="Main_Settings"
        if notificationsSubtitlesEnabled==false
            debug.notification("Subtitles are OFF")
        else
            debug.notification("Subtitles are ON")
        endif
        if !(Game.GetPlayer().HasPerk(ActivatePerk))
            debug.notification("Alt conversation start option is OFF")
        else
            debug.notification("Alt conversation start option is ON")
        endif
    elseif aMenu=="HTTP_Settings"
        debug.notification("The HTTP port is currently "+ConstantsScript.HTTP_PORT)
    elseif aMenu=="Hotkeys"
        if textkeycode!=0
            Debug.notification("Current text response hotkey is "+textkeycode)
        ElseIf (true)
            Debug.notification("Current text response hotkey is unassigned")
        endif
        if gameEventkeycode!=0
            Debug.notification("Current custom game event input hotkey is "+gameEventkeycode)
        ElseIf (true)
            Debug.notification("Current custom game event input hotkey is unassigned")
        endif
        if startConversationkeycode!=0
            Debug.notification("Current start conversation hotkey is "+startConversationkeycode)
        ElseIf (true)
            Debug.notification("Current start conversation hotkey is unassigned")
        endif
        if textAndVisionKeycode!=0
            Debug.notification("Current text response and vision hotkey is "+textAndVisionKeycode)
        ElseIf (true)
            Debug.notification("Current text response and vision hotkey is unassigned")
        endif
        if MantellaVisionKeycode!=0
            Debug.notification("Current Mantella Vision (screenshot) hotkey is "+MantellaVisionKeycode)
        ElseIf (true)
            Debug.notification("Current Mantella Vision (screenshot) hotkey is unassigned")
        endif
    elseif aMenu=="Events"
        if playerTrackingOnItemAdded
            Debug.notification("Player events are being tracked by Mantella")
        else
            Debug.notification("Player events are NOT being tracked by Mantella")
        endif
        if targetTrackingItemAdded
            Debug.notification("NPCs events are being tracked by Mantella")
        else
            Debug.notification("NPCs events are NOT being tracked by Mantella")
        endif
        if allowCrosshairTracking
            Debug.notification("F4SE crosshair tracking is ON")
        else
            Debug.notification("F4SE crosshair tracking is OFF")
        endif
    elseif aMenu=="Vision"
        if allowVision==false
            debug.notification("Vision analysis is OFF")
        else
            debug.notification("Vision analysis is ON")
        endif
        debug.notification("Vision resolution is set to "+visionResolution)
        debug.notification("Images will be resized to "+visionResize)
    endif
EndFunction

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    if (asMenuName== "PipboyMenu") && MenuEventSelector==1 && !abOpening ;This triggers if the player chooses to change the text input hotkey
	    OpenHotkeyPrompt("playerInputTextHotkey")
    elseif (asMenuName== "PipboyMenu") && MenuEventSelector==2 && !abOpening ;This triggers if the player chooses to stop all conversations
        StopConversations()
        debug.notification("Attempting to stop all conversations")
        UnregisterForMenuOpenCloseEvent("PipboyMenu")
    elseif (asMenuName== "PipboyMenu") && MenuEventSelector==3 && !abOpening ;This triggers if the player chooses to change the HTTP port
        Open_HTTP_Port_Prompt()
    elseif(asMenuName== "PipboyMenu") && MenuEventSelector==4 && !abOpening
	    OpenHotkeyPrompt("gameEventHotkey")  
    elseif(asMenuName== "PipboyMenu") && MenuEventSelector==5 && !abOpening
	    OpenHotkeyPrompt("startConversationHotKey")  
    elseif(asMenuName== "PipboyMenu") && MenuEventSelector==6 && !abOpening
	    OpenHotkeyPrompt("playerInputTextAndVisionHotkey")     
    elseif(asMenuName== "PipboyMenu") && MenuEventSelector==7 && !abOpening
	    OpenHotkeyPrompt("playerInputMantellaVisionHotkey")     
    endif
endEvent



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Hotkey functions    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Event Onkeydown(int keycode)
    bool menuMode = TopicInfoPatcher.isMenuModeActive()
    ;Debug.TraceUser("MC", "OnKeyDown " + keycode)
    if !menuMode
        if keycode == MantellaVisionKeycode
            GenerateMantellaVision()
        endif
        If conversation.IsRunning() 
            if (keycode == textAndVisionKeycode )
                conversation.GetPlayerTextInput("playerResponseTextAndVisionEntry")
            elseif (keycode == textkeycode )
                conversation.GetPlayerTextInput("playerResponseTextEntry")
            ElseIf keycode == gameEventkeycode
                conversation.GetPlayerTextInput("gameEventEntry")
            EndIf
        Endif
        if CrosshairActor!=none && keycode == startConversationkeycode
            String actorName = CrosshairActor.GetDisplayName()
            bool isTargetInConversation = conversation.IsActorInConversation(CrosshairActor)
            float distanceFromConversationTarget = Game.GetPlayer().GetDistance(CrosshairActor)

            if distanceFromConversationTarget<1500
                ; if actor not already loaded or player is interrupting radiant dialogue
                bool bIsPlayerInConversation = conversation.IsPlayerInConversation()
                
                if !isTargetInConversation
                    debug.notification("Attempting to start conversation with "+CrosshairActor.GetDisplayName())
                    MantellaSpell.cast(Game.GetPlayer(), CrosshairActor)
                ElseIf !bIsPlayerInConversation
                    debug.notification("Adding player to radiant conversation with "+CrosshairActor.GetDisplayName())
                    MantellaSpell.cast(CrosshairActor, Game.GetPlayer())
                endif
                Utility.Wait(0.5)
            endif
        Endif
    EndIf
Endevent

function setHotkey(int keycode, string keyType)
    if keyType=="Dialogue"
        unRegisterForKey(textkeycode)
        textkeycode = keycode
        RegisterForKey(textkeycode)
    elseif keyType=="GameEvent"
        unRegisterForKey(gameEventkeycode)
        gameEventkeycode = keycode
        RegisterForKey(gameEventkeycode)
    elseif keyType=="StartConversation"
        unRegisterForKey(startConversationkeycode)
        startConversationkeycode = keycode
        RegisterForKey(startConversationkeycode)
    elseif keyType=="DialogueAndVision"
        unRegisterForKey(textAndVisionKeycode)
        textAndVisionKeycode = keycode
        RegisterForKey(textAndVisionKeycode)
    elseif keyType=="MantellaVision"
        unRegisterForKey(MantellaVisionKeycode)
        MantellaVisionKeycode = keycode
        RegisterForKey(MantellaVisionKeycode)
    endif
endfunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Crosshair functions    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function CrosshairRefCallback(bool bCrosshairOn, ObjectReference ObjectRef, int Type)
    ;debug.notification("Object ref is "+ObjectRef.getdisplayname())
    if bCrosshairOn
        if Type==65 ;checks if type is actor
            CrosshairActor= ObjectRef as actor
            ;debug.notification(" type is "+Type)
        endif
    endif
Endfunction

Function RegisterForOnCrosshairRefChange()
    ;disable for VR
    ;RegisterForSUPEvent("OnCrosshairRefChange", self as Form, "MantellaRepository", "CrosshairRefCallback",true,true,false, 0) 
    allowCrosshairTracking=true
EndFunction

Function UnRegisterForOnCrosshairRefChange()
    ;disable for VR
    ;UnregisterForAllSUPEvents("OnCrosshairRefChange", self as Form,true, "MantellaRepository", "CrosshairRefCallback")
    CrosshairActor=none
    allowCrosshairTracking=false
EndFunction


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Textinput menu functions    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


function OpenHotkeyPrompt(string entryType)
    ;disable for VR
    if entryType == "playerInputTextHotkey"
        SimpleTextField.Open(self as ScriptObject, "TIMSetDialogueHotkeyInput","Enter the DirectX Scancode for the dialogue hotkey")
        UnregisterForMenuOpenCloseEvent("PipboyMenu")
    elseif entryType == "gameEventHotkey"
        SimpleTextField.Open(self as ScriptObject, "TIMGameEventHotkeyInput","Enter the DirectX Scancode for the game event hotkey")
        UnregisterForMenuOpenCloseEvent("PipboyMenu")
    elseif entryType == "startConversationHotKey"
        SimpleTextField.Open(self as ScriptObject, "TIMStartConversationHotkeyInput","Enter the DirectX Scancode for the start converstion hotkey")
        UnregisterForMenuOpenCloseEvent("PipboyMenu")
    elseif entryType == "playerInputTextAndVisionHotkey"
        SimpleTextField.Open(self as ScriptObject, "TIMSetDialogueAndVisionHotkeyInput","Enter the DirectX Scancode for the dialogue and vision hotkey")
        UnregisterForMenuOpenCloseEvent("PipboyMenu")
    elseif entryType == "playerInputMantellaVisionHotkey"
        SimpleTextField.Open(self as ScriptObject, "TIMSetMantellaVisionHotkeyInput","Enter the DirectX Scancode for the Mantella Vision (screenshot) hotkey")
        UnregisterForMenuOpenCloseEvent("PipboyMenu")
    endif

endfunction

Function TIMSetDialogueHotkeyInput(string keycode)
    ;Debug.notification("This text input was entered "+ text)
    keycode = TopicInfoPatcher.StringRemoveWhiteSpace(keycode)
    if keycode == ""
        return
    Endif
    setHotkey(keycode as int, "Dialogue")
EndFunction

Function TIMGameEventHotkeyInput(string keycode)
    ;Debug.notification("This text input was entered "+ text)
    keycode = TopicInfoPatcher.StringRemoveWhiteSpace(keycode)
    if keycode == ""
        return
    Endif
    setHotkey(keycode as int, "GameEvent")
EndFunction

Function TIMStartConversationHotkeyInput(string keycode)
    ;Debug.notification("This text input was entered "+ text)
    keycode = TopicInfoPatcher.StringRemoveWhiteSpace(keycode)
    if keycode == ""
        return
    Endif
    setHotkey(keycode as int, "StartConversation")
EndFunction

Function TIMSetDialogueAndVisionHotkeyInput(string keycode)
    ;Debug.notification("This text input was entered "+ text)
    keycode = TopicInfoPatcher.StringRemoveWhiteSpace(keycode)
    if keycode == ""
        return
    Endif
    setHotkey(keycode as int, "DialogueAndVision")
EndFunction

Function TIMSetMantellaVisionHotkeyInput(string keycode)
    ;Debug.notification("This text input was entered "+ text)
    keycode = TopicInfoPatcher.StringRemoveWhiteSpace(keycode)
    if keycode == ""
        return
    Endif
    setHotkey(keycode as int, "MantellaVision")
EndFunction

function Open_HTTP_Port_Prompt()
    SimpleTextField.Open(self as ScriptObject, "TIM_Set_HTTP_Port","Enter the HTTP port, use a value between 0 and 65535")
    UnregisterForMenuOpenCloseEvent("PipboyMenu")
endfunction

Function TIM_Set_HTTP_Port(string HTTP_port)
    ;Debug.notification("This text input was entered "+ text)
    HTTP_port = TopicInfoPatcher.StringRemoveWhiteSpace(HTTP_port)
    if HTTP_port == ""
        return
    Endif
    ConstantsScript.HTTP_PORT = (HTTP_port as int)
EndFunction
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Vision functions    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function GenerateMantellaVision()
    hasPendingVisionCheck=true
    TopicInfoPatcher.TakeScreenShot("Mantela_vision.png", 3)
EndFunction

bool Function checkAndUpdateVisionPipeline()
    ;automatically triggers to false to allow Camera and Spell to send the vision value only once per exchange.
    if allowVision || hasPendingVisionCheck
        hasPendingVisionCheck=false
        return true
    else
        return false
    endif
EndFunction


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   NPC array management    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Actor[] Function ScanCellForActors(bool filteredByPlayerLOS) 
    Actor playerRef = Game.GetPlayer()
    Actor[] ActorsInCell
    Actor[] ActorsInCellProcessed
    ActorsInCell = SUP_F4SE.GetActorsInCell(playerRef.GetParentCell(), -1)
    if filteredByPlayerLOS
        int i
        int FilteredActorCount
            While i < ActorsInCell.Length
                Actor currentActor = ActorsInCell[i]
                if playerRef.HasDetectionLOS (currentActor)
                    float currentDistance = playerRef.GetDistance(currentActor)
                    if currentActor.GetDisplayName()!="" && currentDistance<5000
                        ActorsInCellProcessed.add(ActorsInCell[i])
                    endif
                endif
                i += 1
            EndWhile
        ActorsInCell=ActorsInCellProcessed
    endif
    return ActorsInCell
Endfunction

Function DispelAllMantellaMagicEffectsFromActors(Actor[] ActorArray)
    int i=0
    While i < ActorArray.Length
        Actor actorToDispel = ActorArray[i]
        actorToDispel.DispelSpell(MantellaSpell)
        i += 1
    EndWhile
Endfunction

;/
Function ScanCellForActors(bool filtered) ;to implement to give cues on NPC locations
    Actor playerRef = Game.GetPlayer()
    Actor[] ActorsInCell
    String[] FilteredActorsInCellNames = new String[0]
    Float[] FilteredActorsInCellDistanceFromPlayer = new Float[0]
    ActorsInCell = SUP_F4SE.GetActorsInCell(playerRef.GetParentCell(), -1)
    int i
    int FilteredActorCount
        While i < ActorsInCell.Length
            Actor currentActor = ActorsInCell[i]
            if playerRef.HasDetectionLOS (currentActor)
                float currentDistance = playerRef.GetDistance(currentActor)
                if currentActor.GetDisplayName()!="" && currentDistance<5000
                    FilteredActorsInCellNames.Add(currentActor.GetDisplayName())
                    FilteredActorsInCellDistanceFromPlayer.Add(currentDistance)
                    FilteredActorCount += 1
                endif
            endif
            i += 1
        EndWhile
Endfunction
/;
String function ConvertActorAndDistanceArrayToString(Actor[] ActorNamesArray, Float[] DistanceArray)
    int k
    string actorList
    string distancelist
    While k < ActorNamesArray.Length
        actorList += "Name : "+ActorNamesArray[k]+", distance : "+DistanceArray[k]+", "
        k += 1
    EndWhile
    return actorList
Endfunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Player and NPC state reporting   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

string function constructPlayerState()
    String[] playerStateArray = new String[10]
    string playerState = "The player is "
    int playerStatePositiveCount=0
    Actor playerRef = Game.GetPlayer()
    if playerRef.IsInPowerArmor()
        playerStateArray[playerStatePositiveCount]="in power armor"  
        playerStatePositiveCount+=1
    endif
    if playerRef.IsOverEncumbered()
        playerStateArray[playerStatePositiveCount]="overencumbered"  
        playerStatePositiveCount+=1
    endif
    if playerRef.IsSneaking()
        playerStateArray[playerStatePositiveCount]="sneaking"  
        playerStatePositiveCount+=1
    endif
    if playerRef.IsBleedingOut()
        playerStateArray[playerStatePositiveCount]="bleeding out"  
        playerStatePositiveCount+=1
    endif
    if 0.9 > getRadFactoredPercentHealth(playerRef) && getRadFactoredPercentHealth(playerRef) >= 0.7
        playerStateArray[playerStatePositiveCount]="lightly wounded"  
        playerStatePositiveCount+=1
    ElseIf 0.7 > getRadFactoredPercentHealth(playerRef) && getRadFactoredPercentHealth(playerRef) >= 0.4
        playerStateArray[playerStatePositiveCount]="moderately wounded" 
        playerStatePositiveCount+=1
    ElseIf 0.4 > getRadFactoredPercentHealth(playerRef) 
        playerStateArray[playerStatePositiveCount]="heavily wounded" 
        playerStatePositiveCount+=1
    endif
    if getRadPercent(playerRef) > 0.05 && getRadPercent(playerRef) <= 0.3
        playerStateArray[playerStatePositiveCount]="lightly irradiated"  
        playerStatePositiveCount+=1
    ElseIf getRadPercent(playerRef) > 0.3 && getRadPercent(playerRef) <= 0.6
        playerStateArray[playerStatePositiveCount]="moderately irradiated" 
        playerStatePositiveCount+=1
    ElseIf 0.6 < getRadPercent(playerRef) 
        playerStateArray[playerStatePositiveCount]="heavily irradiated" 
        playerStatePositiveCount+=1
    endif

    if playerStatePositiveCount>0
        playerState += playerStateArray[0]
        if playerStatePositiveCount>2
            playerState += ", "
         endif
    endif
    int i=1
    while i <= (playerStatePositiveCount-2)
        if i == playerStatePositiveCount
            playerState += playerStateArray[i]
        else
            playerState += playerStateArray[i] + ", "
        endif
        i+=1
    endwhile
    ; Add the last entry with a different separator if there is more than one entry
    If playerStatePositiveCount > 1
        playerState += " & " 
        playerState+= playerStateArray[playerStatePositiveCount - 1]
    EndIf
    

    ;debug.notification(playerState)
    if playerStatePositiveCount>0
        return playerState
    Else
        return ""
    endIf
endfunction

float function getRadPercent(actor currentActor)
    float radPercent
    radPercent=((currentActor.getvalue(RadsAV)) * radiationToHealthRatio) / (currentActor.getvalue(HealthAV)/currentActor.GetValuePercentage(HealthAV))
    return radPercent
endfunction

float function getRadFactoredMaxHealth(actor currentActor)
    float MaxHealth= currentActor.getvalue(HealthAV)/currentActor.GetValuePercentage(HealthAV)
    float radPercent
    float radFactoredMaxHealth=MaxHealth*(1-getRadPercent(currentActor))
    return radFactoredMaxHealth
endfunction

float function getRadFactoredPercentHealth(actor currentActor)
    float radFactoredPercentHealth= currentActor.getvalue(HealthAV)/getRadFactoredMaxHealth(currentActor)
  
    return radFactoredPercentHealth
endfunction


;Proxy functions for calling the SimpleTextField dialog
;The code handling the callback would occasionaly get confused
;When calling back to MantellaConversation because
;MantellaConversation quest has two scripts associated with it: MantellaConversation and
;MantellaConstants. It would sometimes try calling back to the wrong one.
;Since MantellaQuest has only a single script, no confusion occurs and
;we just call the requested function from here

Function TextInputCB(string text)
    var[] _args = new var[1]
    _args[0] = text
    ;Debug.TraceUser("MC", "TextInput CB: " + CBScript + ":" + CBfunction)
    CBscript.CallFunctionNoWait(CBfunction,_args)
EndFunction

Function GetTextInput(ScriptObject akReceiver, string asFunctionName, string asTitle = "", string asText = "")
    ;Debug.TraceUser("MC", "GetTextInput " + asTitle)
    CBscript = akReceiver
    CBfunction = asFunctionName
    SimpleTextField.Open(self as ScriptObject, "TextInputCB", asTitle, asText)   
EndFunction


