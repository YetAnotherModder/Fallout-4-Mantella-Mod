Scriptname MantellaRepository extends Quest Conditional
Import SUP_F4SE
Import SUP_F4SEVR
Import TIM:TIM

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
Quest Property MantellaVisibleCollectionQuest Auto 
RefCollectionAlias Property MantellaVisibleNPCRefCollection  Auto
Quest Property MantellaNPCCollectionQuest Auto 
RefCollectionAlias Property MantellaNPCCollection  Auto


;endFlagMantellaConversationOne exists to prevent conversation loops from getting stuck on NPCs if Mantella crashes or interactions gets out of sync
bool property endFlagMantellaConversationOne auto
string property currentFO4version auto
int property currentSUPversion auto
bool property isFO4VR auto Conditional
bool property microphoneEnabled auto
bool property radiantEnabled auto
float property radiantDistance auto
float property radiantFrequency auto

;vision parameters
bool property hideVisionMenu auto Conditional
bool property allowVision auto Conditional
bool property allowVisionHints auto Conditional
bool property hasPendingVisionCheck auto
string property visionResolution auto
int property visionResize auto Conditional
String property ActorsInCellArray auto
String property VisionDistanceArray auto

;function calling parameters
bool property hideFunctionMenu auto Conditional
bool property allowFunctionCalling auto Conditional
Quest Property MantellaFunctionNPCCollectionQuest Auto 
RefCollectionAlias Property MantellaFunctionNPCCollection  Auto
Actor[] Property MantellaFunctionInferenceActorList  Auto
String Property MantellaFunctionInferenceActorNamesList  Auto
String Property MantellaFunctionInferenceActorDistanceList  Auto
String Property MantellaFunctionInferenceActorIDsList  Auto
bool property AIPackageMoveToNPCIsActivated auto Conditional


bool property allowActionAggro auto
bool property allowNPCsStayInPlace auto Conditional
bool property allowFollow auto
bool property allowActionInventory auto Conditional
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
    hideVisionMenu=true
    textkeycode=72
    gameEventkeycode=89
    startConversationkeycode=72
    reloadKeys()
    radiantEnabled = true
    radiantDistance = 20
    radiantFrequency = 10
    allowVision = false
    allowVisionHints = true
    allowFunctionCalling = false
    visionResolution="auto"
    visionResize=1024
    allowActionAggro = false
    allowActionInventory = false
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

Function toggleAllowAggro(bool bswitch)
    allowActionAggro = bswitch
    if bswitch
        Debug.notification("NPC are now allowed to aggro")
    else
        Debug.notification("NPC are not allowed to aggro")
    endif
EndFunction

Function toggleAllowFollow(bool bswitch)
    allowFollow = bswitch
EndFunction

Function toggleActionInventory(bool bswitch)
    allowActionInventory = bswitch
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

Function toggleAllowFunctionCalling(bool bswitch)
    allowFunctionCalling = bswitch
    if allowFunctionCalling
        ;toggle NPC Stay in Place as well since function calling depends on it.
        toggleAllowNPCsStayInPlace(true)  
    endif
    if bswitch
        Debug.notification("Function Calling is now ON")
    else
        Debug.notification("Function Calling is now OFF")
    endif
EndFunction

Function toggleAllowVisionHints(bool bswitch)
    allowVisionHints = bswitch
    if bswitch
        Debug.notification("Vision hints are now ON")
    else
        Debug.notification("Vision hints are now OFF")
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
        if allowActionAggro==false
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
    ;if !SUP_F4SE.IsMenuModeActive() 
    if !Utility.IsInMenuMode()
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
    if !isFO4VR
        SUP_F4SE.RegisterForSUPEvent("OnCrosshairRefChange", self as Form, "MantellaRepository", "CrosshairRefCallback",true,true,false, 0) 
        allowCrosshairTracking=true
    endif
EndFunction

Function UnRegisterForOnCrosshairRefChange()
    ;disable for VR
    if !isFO4VR
        SUP_F4SE.UnregisterForAllSUPEvents("OnCrosshairRefChange", self as Form,true, "MantellaRepository", "CrosshairRefCallback")
        CrosshairActor=none
        allowCrosshairTracking=false
    endif
EndFunction


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Textinput menu functions    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


function OpenHotkeyPrompt(string entryType)
    ;disable for VR
    if !isFO4VR
        if entryType == "playerInputTextHotkey"
            if conversation.UseSimpleTextField
                SimpleTextField.Open(self as ScriptObject, "TIMSetDialogueHotkeyInput","Enter the DirectX Scancode for the dialogue hotkey")
            Else
                TIM:TIM.Open(1,"Enter the DirectX Scancode for the dialogue hotkey","", 0, 3)
                RegisterForExternalEvent("TIM::Accept","TIMSetDialogueHotkeyInput")
                RegisterForExternalEvent("TIM::Cancel","TIMNoDialogueHotkeyInput")
            EndIf
            UnregisterForMenuOpenCloseEvent("PipboyMenu")
        elseif entryType == "gameEventHotkey"
            if conversation.UseSimpleTextField
                SimpleTextField.Open(self as ScriptObject, "TIMGameEventHotkeyInput","Enter the DirectX Scancode for the game event hotkey")
            Else
                TIM:TIM.Open(1,"Enter the DirectX Scancode for the game event hotkey","", 0, 3)
                RegisterForExternalEvent("TIM::Accept","TIMGameEventHotkeyInput")
                RegisterForExternalEvent("TIM::Cancel","TIMNoDialogueHotkeyInput")
            EndIf
            UnregisterForMenuOpenCloseEvent("PipboyMenu")
        elseif entryType == "startConversationHotKey"
            if conversation.UseSimpleTextField
                SimpleTextField.Open(self as ScriptObject, "TIMStartConversationHotkeyInput","Enter the DirectX Scancode for the start converstion hotkey")
            Else
                TIM:TIM.Open(1,"Enter the DirectX Scancode for the start converstion hotkey","", 0, 3)
                RegisterForExternalEvent("TIM::Accept","TIMStartConversationHotkeyInput")
                RegisterForExternalEvent("TIM::Cancel","TIMNoDialogueHotkeyInput")
            EndIf
            UnregisterForMenuOpenCloseEvent("PipboyMenu")
        elseif entryType == "playerInputTextAndVisionHotkey"
            if conversation.UseSimpleTextField
                SimpleTextField.Open(self as ScriptObject, "TIMSetDialogueAndVisionHotkeyInput","Enter the DirectX Scancode for the dialogue and vision hotkey")
            Else
                TIM:TIM.Open(1,"Enter the DirectX Scancode for the dialogue and vision hotkey","", 0, 3)
                RegisterForExternalEvent("TIM::Accept","TIMSetDialogueAndVisionHotkeyInput")
                RegisterForExternalEvent("TIM::Cancel","TIMNoDialogueHotkeyInput")
            EndIf
            UnregisterForMenuOpenCloseEvent("PipboyMenu")
        elseif entryType == "playerInputMantellaVisionHotkey"
            if conversation.UseSimpleTextField
                SimpleTextField.Open(self as ScriptObject, "TIMSetMantellaVisionHotkeyInput","Enter the DirectX Scancode for the Mantella Vision (screenshot) hotkey")
            Else
                TIM:TIM.Open(1,"Enter the DirectX Scancode for the Mantella Vision (screenshot) hotkey","", 0, 3)
                RegisterForExternalEvent("TIM::Accept","TIMSetMantellaVisionHotkeyInput")
                RegisterForExternalEvent("TIM::Cancel","TIMNoDialogueHotkeyInput")
            EndIf
            UnregisterForMenuOpenCloseEvent("PipboyMenu")
        Endif
    endif

endfunction

Function TIMSetDialogueHotkeyInput(string keycode)
    ;Debug.notification("This text input was entered "+ text)
    if !isFO4VR
        If conversation.UseSimpleTextField
            keycode = SUPF4SEformatText(keycode)
            if keycode == ""
                return
            Endif
        Else
            UnRegisterForExternalEvent("TIM::Accept")
            UnRegisterForExternalEvent("TIM::Cancel")
        EndIf
        setHotkey(keycode as int, "Dialogue")
    endif
EndFunction

Function TIMGameEventHotkeyInput(string keycode)
    ;Debug.notification("This text input was entered "+ text)
    if !isFO4VR
        If conversation.UseSimpleTextField
            keycode = SUPF4SEformatText(keycode)

            if keycode == ""
                return
            Endif
        Else
            UnRegisterForExternalEvent("TIM::Accept")
            UnRegisterForExternalEvent("TIM::Cancel")
        EndIf
        setHotkey(keycode as int, "GameEvent")
    endif
EndFunction

Function TIMStartConversationHotkeyInput(string keycode)
    ;Debug.notification("This text input was entered "+ text)
    if !isFO4VR
        If conversation.UseSimpleTextField
            keycode = SUPF4SEformatText(keycode)
            if keycode == ""
                return
            Endif
        Else
            UnRegisterForExternalEvent("TIM::Accept")
            UnRegisterForExternalEvent("TIM::Cancel")
        EndIf
        setHotkey(keycode as int, "StartConversation")
    endif
EndFunction

Function TIMSetDialogueAndVisionHotkeyInput(string keycode)
    ;Debug.notification("This text input was entered "+ text)
    if !isFO4VR    
        If conversation.UseSimpleTextField
            keycode = SUPF4SEformatText(keycode)
            if keycode == ""
                return
            Endif
        Else
            UnRegisterForExternalEvent("TIM::Accept")
            UnRegisterForExternalEvent("TIM::Cancel")
        EndIf
        setHotkey(keycode as int, "DialogueAndVision")
    endif
EndFunction

Function TIMSetMantellaVisionHotkeyInput(string keycode)
    ;Debug.notification("This text input was entered "+ text)
    if !isFO4VR    
        If conversation.UseSimpleTextField
            keycode = SUPF4SEformatText(keycode)
            if keycode == ""
                return
            Endif
        Else
            UnRegisterForExternalEvent("TIM::Accept")
            UnRegisterForExternalEvent("TIM::Cancel")
        EndIf
        setHotkey(keycode as int, "MantellaVision")
    endif
EndFunction

Function TIMNoDialogueHotkeyInput(string keycode)
    ;Debug.notification("Text input cancelled")
    if !isFO4VR
        UnRegisterForExternalEvent("TIM::Accept")
        UnRegisterForExternalEvent("TIM::Cancel")
    endif
EndFunction

function Open_HTTP_Port_Prompt()
    if !isFO4VR
        if conversation.UseSimpleTextField
            SimpleTextField.Open(self as ScriptObject, "TIM_Set_HTTP_Port","Enter the HTTP port, use a value between 0 and 65535")
        Else
            TIM:TIM.Open(1,"Enter the HTTP port, use a value between 0 and 65535","", 0, 5)
            RegisterForExternalEvent("TIM::Accept","TIM_Set_HTTP_Port")
            RegisterForExternalEvent("TIM::Cancel","TIM_No_Set_HTTP_Port")
        Endif
        UnregisterForMenuOpenCloseEvent("PipboyMenu")
    endif
    ;
endfunction

Function TIM_Set_HTTP_Port(string HTTP_port)
    ;Debug.notification("This text input was entered "+ text)
    if !isFO4VR
        If conversation.UseSimpleTextField
            HTTP_port = SUPF4SEformatText(HTTP_port)
            if HTTP_port ==""
                return
            Endif
        Else
            UnRegisterForExternalEvent("TIM::Accept")
            UnRegisterForExternalEvent("TIM::Cancel")
        Endif
        ConstantsScript.HTTP_PORT = (HTTP_port as int)
    endif
EndFunction
    
Function TIM_No_Set_HTTP_Port(string keycode)
    ;Debug.notification("Text input cancelled")
    if !isFO4VR
        UnRegisterForExternalEvent("TIM::Accept")
        UnRegisterForExternalEvent("TIM::Cancel")
    endif
EndFunction


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Vision functions    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function GenerateMantellaVision()
    hasPendingVisionCheck=true
    TopicInfoPatcher.TakeScreenShot("Mantella_Vision.jpg", 0) 
    if allowVisionHints
        ScanCellForActorsFilteredLOS()
    endif   
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
Function ScanCellForActorsFilteredLOS() 
    Actor playerRef = Game.GetPlayer()
    Actor[] ActorsInCell = new Actor[0]
    float[] currentDistanceArray = new float[0]
    MantellaVisibleCollectionQuest.start()
    int icount = MantellaVisibleNPCRefCollection.GetCount()
    int iindex = 0
    while (iindex < icount)
        Actor Actori = MantellaVisibleNPCRefCollection.GetAt(iindex) as Actor
        float currentDistance = playerRef.GetDistance(Actori)
        if Actori.GetDisplayName()!="" && playerRef.HasDetectionLOS (Actori)
            ActorsInCell.add(Actori)
            currentDistanceArray.add(currentDistance)
        endif
        iindex = iindex + 1
    endwhile
    MantellaVisibleCollectionQuest.stop()
    ActorsInCellArray=ActorsArrayToString(ActorsInCell)
    VisionDistanceArray = currentDistanceArrayToString(currentDistanceArray)
Endfunction

Actor[] Function ScanAndReturnNearbyActors(quest QuestForScan, RefCollectionAlias RefCollectionToUse) 
    Actor[] ActorsInCell = new Actor[0]
    QuestForScan.start()
    int icount = RefCollectionToUse.GetCount()
    int iindex = 0
    while (iindex < icount)
        Actor Actori = RefCollectionToUse.GetAt(iindex) as Actor
        ActorsInCell.add(Actori)
        iindex = iindex + 1
    endwhile
    QuestForScan.stop()
    return ActorsInCell
Endfunction

Function UpdateFunctionInferenceNPCArrays(Actor[] ActorArray) 
    actor playerRef = game.GetPlayer()
    Float[] currentDistanceArray = new Float[0]
    String[] currentFormIDArray = new String[0]
    int icount = ActorArray.Length
    int iindex = 0
    MantellaFunctionInferenceActorList = new Actor[0]
    while (iindex < icount)
        Actor Actori = ActorArray[iindex]
        float currentDistance = playerRef.GetDistance(Actori)
        string currentFormID = Actori.GetFormID() as string
        MantellaFunctionInferenceActorList.add(Actori)
        currentDistanceArray.add(currentDistance)
        currentFormIDArray.add(currentFormID)
        iindex = iindex + 1
    endwhile
    MantellaFunctionInferenceActorNamesList=ActorsArrayToString(MantellaFunctionInferenceActorList)
    MantellaFunctionInferenceActorDistanceList = currentDistanceArrayToString(currentDistanceArray)
    MantellaFunctionInferenceActorIDsList = ActorsArrayToFormIDString(MantellaFunctionInferenceActorList)
Endfunction



;/ DEPRECATED TO REMOVE SUP_F4SE DEPENDENCIES
Actor[] Function ScanCellForActors(bool filteredByPlayerLOS, bool updateProperties) 
    ;if filteredByPlayerLOS is turned on this only returns an array of actors visible to the player
    ;if updateProperties is turned on it will fill the properties of ActorsInCellArray & currentDistanceArray with the scanned actors names and distances
    ;if updateProperties is turned off it will return the values of the actors in array form
    Actor playerRef = Game.GetPlayer()
    Actor[] ActorsInCellProcessed = new Actor[0]
    Actor[] ActorsInCell = new Actor[0]
    float[] currentDistanceArrayProcessed = new float[0]
    ActorsInCell = SUP_F4SEScanCellMethodSelector(playerRef)
    if filteredByPlayerLOS
        int i
        While i < ActorsInCell.Length
            Actor currentActor = ActorsInCell[i]
            if playerRef.HasDetectionLOS (currentActor)
                float currentDistance = playerRef.GetDistance(currentActor)
                 if currentActor.GetDisplayName()!="" && currentDistance<5000 && currentActor != PlayerRef
                    ActorsInCellProcessed.add(ActorsInCell[i])
                    currentDistanceArrayProcessed.add(currentDistance)
                endif
            endif
            i += 1
        EndWhile
    endif
    if updateProperties
        ActorsInCellArray=ActorsArrayToString(ActorsInCellProcessed)
        VisionDistanceArray = currentDistanceArrayToString(currentDistanceArrayProcessed)
    else
        return ActorsInCell
    endif
Endfunction
/;

String Function ActorsArrayToString (Actor[] ActorArray)
    string StringOutput
    int i = 0
    string currentActorName =""
    While i < ActorArray.Length
        Actor currentActor = ActorArray[i]
        currentActorName = currentActor.GetDisplayName()
        StringOutput += "["+currentActorName+"]"
        if i != (ActorArray.Length-1)
            StringOutput += ","
        endif
        i += 1
    EndWhile
    return StringOutput
Endfunction

String Function currentDistanceArrayToString (Float[] currentDistanceArray)
    string StringOutput
    int i = 0
    While i < currentDistanceArray.Length
        float currentDistance = currentDistanceArray[i]
        StringOutput += "["+currentDistance+"]"
        if i != (currentDistanceArray.Length-1)
            StringOutput += ","
        endif
        i += 1
    EndWhile
    return StringOutput
Endfunction

String Function ActorsArrayToFormIDString (Actor[] ActorArray)
    string StringOutput
    int i = 0
    string currentActorFormID =""
    While i < ActorArray.Length
        Actor currentActor = ActorArray[i]
        currentActorFormID = currentActor.GetFormID()
        StringOutput += "["+currentActorFormID+"]"
        if i != (ActorArray.Length-1)
            StringOutput += ","
        endif
        i += 1
    EndWhile
    return StringOutput
Endfunction

Function resetVisionHintsArrays()
    ActorsInCellArray=""
    VisionDistanceArray = ""
Endfunction

Function resetFunctionInferenceNPCArrays()
    MantellaFunctionInferenceActorNamesList=""
    MantellaFunctionInferenceActorDistanceList=""
    MantellaFunctionInferenceActorIDsList=""
Endfunction

Actor Function getActorFromArray(string targetID, actor[] actorarray)
    int i = 0
    int convertedTargetID = targetID as int
    While i < actorarray.Length
        Actor currentActor = actorarray[i]
        if currentActor.GetFormID() == convertedTargetID
            return currentActor
        endIf
        i += 1
    EndWhile
    return none
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   SUP_F4SE & SUP_F4SEVR functions   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
int function ReturnSUPF4SEVersion()
    int currentVersion
    if isFO4VR
        currentVersion=SUP_F4SEVR.GetSUPF4SEVersion() 
    else
        currentVersion=SUP_F4SE.GetSUPF4SEVersion() 
    endif
    return currentVersion
endfunction

;/ DEPRECATE REPLACED WITH ScanCellForActorsFilteredLOS()
Actor[] function SUP_F4SEScanCellMethodSelector(actor playerRef)
    Actor[] ActorsInCell = new Actor[0]
    if isFO4VR
        debug.notification("Hints not available on F4SE_VR")
        ;The game will CTD if the function below is enabled.
        ;ActorsInCell = SUP_F4SEVR.GetActorsInCell(playerRef.GetParentCell(), -1)
    else
        ActorsInCell = SUP_F4SE.GetActorsInCell(playerRef.GetParentCell(), -1)
    endif
    return ActorsInCell
endfunction
/;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   SimpleTextFieldfunctions   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
    CBscript.CallFunctionNoWait(CBfunction,_args)
EndFunction

Function GetTextInput(ScriptObject akReceiver, string asFunctionName, string asTitle = "", string asText = "")
    CBscript = akReceiver
    CBfunction = asFunctionName
    SimpleTextField.Open(self as ScriptObject, "TextInputCB", asTitle, asText)   
EndFunction


string function SUPF4SEformatText(string TextToFormat)
    TextToFormat = TopicInfoPatcher.StringRemoveWhiteSpace(TextToFormat)
    return TextToFormat
endfunction


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   LLM Function Calling Functions   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Actor[] Function GetFunctionInferenceActorList ()  
    return ScanAndReturnNearbyActors(MantellaFunctionNPCCollectionQuest ,MantellaFunctionNPCCollection)
Endfunction 


