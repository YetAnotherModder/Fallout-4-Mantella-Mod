Scriptname MantellaRepository extends Quest Conditional

Import MantellaLauncher
;keycode properties
int property textkeycode auto
int property textAndVisionKeycode auto
int property MantellaVisionKeycode auto
int property gameEventkeycode auto
int property startConversationkeycode auto

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
bool property isFO4VR auto Conditional
bool property microphoneEnabled auto Conditional
bool property radiantEnabled auto
float property radiantDistance auto
float property radiantFrequency auto

;vision parameters
bool property hideVisionMenu=false auto Conditional
bool property allowVision auto Conditional
bool property allowVisionHints auto Conditional
bool property hasPendingVisionCheck auto
string property visionResolution auto
int property visionResize auto Conditional
String property ActorsInCellArray auto
String property VisionDistanceArray auto

;function calling parameters
bool property hideFunctionMenu=false auto Conditional
bool property allowFunctionCalling auto Conditional
Quest Property MantellaFunctionNPCCollectionQuest Auto 
RefCollectionAlias Property MantellaFunctionNPCCollection  Auto
Actor[] Property MantellaFunctionInferenceActorList  Auto
String Property MantellaFunctionInferenceActorNamesList  Auto
String Property MantellaFunctionInferenceActorDistanceList  Auto
String Property MantellaFunctionInferenceActorIDsList  Auto
int property NPCAIPackageSelector auto Conditional
;NPCAIPackageSelector values
;-1 = default state
;0 = wait
;1 = follow non-player
;2 = attack
;3 = loot
;4 = use item (item must be specified below)
;5 = follow player
int property NPCAIItemToUseSelector auto Conditional
;1 = stimpak
int property NPCAIItemToLootSelector auto Conditional
;0 = any
;1 = weapon
;2 = armor
;3 = junk
;4 = consumables


int Property HTTPTimeOutHolotapeValue Auto Conditional
bool property allowActionAggro auto Conditional
bool property allowNPCsStayInPlace auto Conditional
bool property allowFollow auto Conditional
bool property allowActionInventory auto Conditional
bool property allowCrosshairTracking auto Conditional
Spell property MantellaSpell auto
Perk property ActivatePerk auto
;variables below for Player game event tracking
bool property playerTrackingOnItemAdded auto Conditional
bool property playerTrackingOnItemRemoved auto Conditional
bool property playerTrackingOnHit auto Conditional
bool property playerTrackingOnLocationChange auto Conditional
bool property playerTrackingOnObjectEquipped auto Conditional
bool property playerTrackingOnObjectUnequipped auto Conditional
bool property playerTrackingOnSit auto Conditional
bool property playerTrackingOnGetUp auto Conditional
bool property playerTrackingFireWeapon auto Conditional
bool property playerTrackingRadiationDamage auto Conditional
bool property playerTrackingSleep auto Conditional
bool property playerTrackingCripple auto Conditional
bool property playerTrackingHealTeammate auto Conditional


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


;player Variables
float property PlayerRadFactoredHealth auto
float property PlayerRadiationPercent auto

;item variables
int property StimpackCount auto
int property RadAwayCount auto

;misc Variabales
ActorValue property HealthAV auto
ActorValue property RadsAV auto
float radiationToHealthRatio = 0.229
Actor property CrosshairActor auto
int CleanupconversationTimer=2

;Callback variables for SimpleTextField
ScriptObject CBscript =  none
string CBfunction
bool Property isFirstConvo = true auto

;tutorial variables
bool property tutorialActivated auto Conditional
bool property showHolotapeSettingsTutorial auto
bool property showHotkeysTutorial auto
bool property showHTTPSettingsTutorial auto
bool property showRadiantSettingsTutorial auto
bool property showVisionSettingsTutorial auto
bool property showNPCActionsTutorial auto
bool property showEventTrackingTutorial auto
bool property showConversationTimeoutTutorial auto

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
    conversation.RestoreSettings()                              ; Make sure Game settings are restored after a load
Endfunction


Function StopConversations()
    If (conversation.IsRunning())
        conversation.EndConversation()
        StartTimer(5,CleanupconversationTimer)              ;Start a timer to make second hard reset if conversation is still running after
        conversation.conversationIsEnding = false
    EndIf
EndFunction

Function RestartMantellaExe()
    Debug.notification("Attempting to restart Mantella.exe")
    LaunchMantellaExe() 
Endfunction

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
    textkeycode=72                  ;H
    gameEventkeycode=89             ;Y
    startConversationkeycode=71     ;G
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
    microphoneEnabled = isFO4VR
    ConstantsScript.HTTP_PORT = 4999
    togglePlayerEventTracking(true)
    toggleTargetEventTracking(true)
    HTTPTimeOutHolotapeValue = 240
    Actor PlayerRef = Game.GetPlayer()
    ; If !(PlayerRef.HasPerk(ActivatePerk))
    ;     PlayerRef.AddPerk(ActivatePerk, False)
    ; Endif
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

Function togglePlayerItemEventTracking(bool bswitch)
    ;Player tracking variables below
    if bswitch
        Debug.notification("Player item pickup/drop event tracking is now ON")
    else
        Debug.notification("Player item pickup/drop event tracking is now OFF")
    endif
    playerTrackingOnItemAdded = bswitch
    playerTrackingOnItemRemoved = bswitch
EndFunction

Function togglePlayerHitEventTracking(bool bswitch)
    ;Player tracking variables below
    if bswitch
        Debug.notification("Player getting hit event tracking is now ON")
    else
        Debug.notification("Player getting hit event tracking is now OFF")
    endif
    playerTrackingOnHit = bswitch
EndFunction

Function togglePlayerLocationChangeEventTracking(bool bswitch)
    ;Player tracking variables below
    if bswitch
        Debug.notification("Player location change event tracking is now ON")
    else
        Debug.notification("Player location change event tracking is now OFF")
    endif
    playerTrackingOnLocationChange = bswitch
EndFunction

Function togglePlayerEquipEventTracking(bool bswitch)
    ;Player tracking variables below
    if bswitch
        Debug.notification("Player item equip/unequip event tracking is now ON")
    else
        Debug.notification("Player item equip/unequip event tracking is now OFF")
    endif
    playerTrackingOnObjectEquipped = bswitch
    playerTrackingOnObjectUnequipped = bswitch
EndFunction

Function togglePlayerSitEventTracking(bool bswitch)
    ;Player tracking variables below
    if bswitch
        Debug.notification("Player sitting or using workbenches event tracking is now ON")
    else
        Debug.notification("Player sitting or using workbenches event tracking is now OFF")
    endif
    playerTrackingOnSit = bswitch
    playerTrackingOnGetUp = bswitch
EndFunction

Function togglePlayerWeaponFireEventTracking(bool bswitch)
    ;Player tracking variables below
    if bswitch
        Debug.notification("Player using their weapon or melee event tracking is now ON")
    else
        Debug.notification("Player using their weapon or melee event tracking is now OFF")
    endif
    playerTrackingFireWeapon = bswitch
EndFunction

Function togglePlayerRadiationDmgEventTracking(bool bswitch)
    ;Player tracking variables below
    if bswitch
        Debug.notification("Player taking radiation damage event tracking is now ON")
    else
        Debug.notification("Player taking radiation damage event tracking is now OFF")
    endif
    playerTrackingRadiationDamage=bswitch
EndFunction

Function togglePlayerSleepEventTracking(bool bswitch)
    ;Player tracking variables below
    if bswitch
        Debug.notification("Player sleeping event tracking is now ON")
    else
        Debug.notification("Player sleeping event tracking is now OFF")
    endif
    playerTrackingSleep = bswitch
EndFunction

Function togglePlayerCrippleEventTracking(bool bswitch)
    ;Player tracking variables below
    if bswitch
        Debug.notification("Player getting crippled event tracking is now ON")
    else
        Debug.notification("Player getting crippled event tracking is now OFF")
    endif
    playerTrackingCripple = bswitch
EndFunction

Function togglePlayerHealTeammateEventTracking(bool bswitch)
    ;Player tracking variables below
    if bswitch
        Debug.notification("Player healing teammates event tracking is now ON")
    else
        Debug.notification("Player healing teammates event tracking is now OFF")
    endif
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
        Debug.notification("NPCs are now allowed to aggro")
    else
        Debug.notification("NPCs are not allowed to aggro")
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
        Debug.notification("Alt conversation activation option is now OFF")
	Else
        PlayerRef.AddPerk(ActivatePerk, False)
        Debug.notification("Alt conversation activation option is now ON")
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

Function SetHTTPTimeoutInMinutes(int inputValue)
    HTTPTimeOutHolotapeValue = (inputValue*120)
    ;Debug.notification("Conversation timeout value now set to "+inputValue+" minutes")
EndFunction


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Pipboy Management    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function listMenuState(String aMenu)
    if aMenu=="Main_Settings"
        if !(Game.GetPlayer().HasPerk(ActivatePerk))
            debug.notification("Alt conversation start option is OFF")
        else
            debug.notification("Alt conversation start option is ON")
        endif
        doMainSettingsTutorial()
    elseif aMenu=="Radiant"
        showRadiantSettingsTutorial()
    elseif aMenu=="HTTP_Settings"
        debug.notification("The HTTP port is currently "+ConstantsScript.HTTP_PORT)
        doHTTPTutorial()
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
        doHotkeysTutorial()
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
        showEventTrackingTutorial()
    elseif aMenu=="Vision"
        debug.notification("Vision resolution is set to "+visionResolution)
        debug.notification("Images will be resized to "+visionResize)
        showVisionSettingsTutorial()
    elseif aMenu=="Conversation_timeout"
        showConversationTimeoutTutorial()
    elseif aMenu=="NPC_Actions"    
        showNPCActionsTutorial()
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
    elseif(asMenuName== "PipboyMenu") && MenuEventSelector==8 && !abOpening
	    ResetTutorial()
        UnregisterForMenuOpenCloseEvent("PipboyMenu")
    endif
endEvent



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Hotkey functions    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Event Onkeydown(int keycode)
    bool menuMode = TopicInfoPatcher.isMenuModeActive()
    if !menuMode
        if keycode == startConversationkeycode
            if allowCrosshairTracking
                float [] Actorxyz = TopicInfoPatcher.GetLastActorCoords()
                CrosshairActor = Game.FindClosestActor(Actorxyz[0], Actorxyz[1], Actorxyz[2], 20.0)
                Debug.Notification("Crosshair actor is: " + CrosshairActor.GetDisplayName())
            endif
            if CrosshairActor != none
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
                    elseif isTargetInConversation
                        debug.notification("Displaying conversation menu for "+CrosshairActor.GetDisplayName())
                        MantellaSpell.cast(Game.GetPlayer(), CrosshairActor)
                    endif
                    Utility.Wait(0.5)

                endif
            EndIf
        Endif

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

Function RegisterForOnCrosshairRefChange()
    ;disable for VR
    if !isFO4VR
        allowCrosshairTracking=true
    endif
EndFunction

Function UnRegisterForOnCrosshairRefChange()
    ;disable for VR
    if !isFO4VR
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
        Endif
    endif

endfunction

Function TIMSetDialogueHotkeyInput(string keycode)
    ;Debug.notification("This text input was entered "+ text)
    if !isFO4VR
        keycode = SUPF4SEformatText(keycode)
        if keycode == ""
            return
        Endif
        setHotkey(keycode as int, "Dialogue")
    endif
EndFunction

Function TIMGameEventHotkeyInput(string keycode)
    ;Debug.notification("This text input was entered "+ text)
    if !isFO4VR
        keycode = SUPF4SEformatText(keycode)

        if keycode == ""
            return
        Endif
    setHotkey(keycode as int, "GameEvent")
    endif
EndFunction

Function TIMStartConversationHotkeyInput(string keycode)
    ;Debug.notification("This text input was entered "+ text)
    if !isFO4VR
        keycode = SUPF4SEformatText(keycode)
        if keycode == ""
            return
        Endif
        setHotkey(keycode as int, "StartConversation")
        allowCrosshairTracking=true
    endif
EndFunction

Function TIMSetDialogueAndVisionHotkeyInput(string keycode)
    ;Debug.notification("This text input was entered "+ text)
    if !isFO4VR    
        keycode = SUPF4SEformatText(keycode)
        if keycode == ""
            return
        Endif
        setHotkey(keycode as int, "DialogueAndVision")
    endif
EndFunction

Function TIMSetMantellaVisionHotkeyInput(string keycode)
    ;Debug.notification("This text input was entered "+ text)
    if !isFO4VR    
        keycode = SUPF4SEformatText(keycode)
        if keycode == ""
            return
        Endif
        setHotkey(keycode as int, "MantellaVision")
    endif
EndFunction

function Open_HTTP_Port_Prompt()
    if !isFO4VR
        SimpleTextField.Open(self as ScriptObject, "TIM_Set_HTTP_Port","Enter the HTTP port, use a value between 1 and 65535")
        UnregisterForMenuOpenCloseEvent("PipboyMenu")
    EndIf
endfunction

Function TIM_Set_HTTP_Port(string HTTP_port)
    ;Debug.notification("This text input was entered "+ text)
    if !isFO4VR
        HTTP_port = SUPF4SEformatText(HTTP_port)
        if HTTP_port ==""
            return
        Endif
        ConstantsScript.HTTP_PORT = (HTTP_port as int)
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

Actor[] Function ScanAndReturnNearbyActors(quest QuestForScan, RefCollectionAlias RefCollectionToUse, bool addPlayerToo) 
    Actor[] ActorsInCell = new Actor[0]
    QuestForScan.start()
    Utility.Wait(0.1)
    int icount = RefCollectionToUse.GetCount()
    int iindex = 0
    while (iindex < icount)
        Actor Actori = RefCollectionToUse.GetAt(iindex) as Actor
        ActorsInCell.add(Actori)
        iindex = iindex + 1
    endwhile
    if addPlayerToo
        ActorsInCell.add(game.getplayer() as Actor)
    endif
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

Function RemoveFactionFromActors(Actor[] ActorArray, faction FactionToRemove)
    ;This function is mostly used to remove NPCs from the MantellaFunctionTargetFaction 
    int i=0
    While i < ActorArray.Length
        Actor actorToDispel = ActorArray[i]
        actorToDispel.RemoveFromFaction(FactionToRemove)
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
    PlayerRadFactoredHealth = getRadFactoredPercentHealth(playerRef)
    PlayerRadiationPercent = getRadPercent(playerRef)

    if 0.9 > PlayerRadFactoredHealth && PlayerRadFactoredHealth >= 0.7
        playerStateArray[playerStatePositiveCount]="lightly wounded"  
        playerStatePositiveCount+=1
    ElseIf 0.7 > PlayerRadFactoredHealth && PlayerRadFactoredHealth >= 0.4
        playerStateArray[playerStatePositiveCount]="moderately wounded" 
        playerStatePositiveCount+=1
    ElseIf 0.4 > PlayerRadFactoredHealth 
        playerStateArray[playerStatePositiveCount]="heavily wounded" 
        playerStatePositiveCount+=1
    endif
    if PlayerRadiationPercent > 0.05 && PlayerRadiationPercent <= 0.3
        playerStateArray[playerStatePositiveCount]="lightly irradiated"  
        playerStatePositiveCount+=1
    ElseIf PlayerRadiationPercent > 0.3 && PlayerRadiationPercent <= 0.6
        playerStateArray[playerStatePositiveCount]="moderately irradiated" 
        playerStatePositiveCount+=1
    ElseIf 0.6 < PlayerRadiationPercent 
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

Actor[] Function GetFunctionInferenceActorList()  
    return ScanAndReturnNearbyActors(MantellaFunctionNPCCollectionQuest ,MantellaFunctionNPCCollection, true)
Endfunction 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Tutorial Functions   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function ResetTutorial()
    TriggerTutorialVariables(true)
    doTutorialIntro()
Endfunction

Function TriggerTutorialVariables(bool aBool)
    tutorialActivated=aBool
    showHolotapeSettingsTutorial=aBool
    showHotkeysTutorial=aBool
    isFirstConvo = aBool
    showHTTPSettingsTutorial = aBool
    showRadiantSettingsTutorial = aBool
    showVisionSettingsTutorial = aBool
    showNPCActionsTutorial = aBool
    showEventTrackingTutorial = aBool
    showConversationTimeoutTutorial = aBool
Endfunction

function doTutorialIntro()
    if tutorialActivated
        Debug.MessageBox("Mantella is now active. Start a conversation using one of the following options:")
        Utility.Wait(0.2)
        If !isFO4VR
            Debug.MessageBox("Approach an NPC and use the 'CONVERSATION' option ('R' key)")
        else
            Debug.MessageBox("Approach an NPC and use the 'CONVERSATION' option ('Grab' key)")
        endif
        Utility.Wait(0.2)
        If !isFO4VR
            Debug.MessageBox("OR: Approach an NPC and use the 'start conversation' key (currently 'G'). You can also use the Mantella Gun to shoot an NPC to start the conversation (the gun does no damage).")
            Utility.Wait(0.2)
        Endif
        Debug.MessageBox("Use the Mantella settings holotape to change key assignments or other options. Mantella will use the keyboard by default but you can turn on the microphone in your holotape.")
        Utility.Wait(0.2)
        Debug.MessageBox("We recommend that you quick save and reload the game to enable all of Mantella's function then try opening the Mantella Settings holotape. It should be in your Pipboy inventory under 'Misc'.")
        Utility.Wait(0.2)
    endif
Endfunction

function doMainSettingsTutorial()
    if tutorialActivated && showHolotapeSettingsTutorial
        debug.MessageBox("In this menu you can completely stop all conversations or reset the Mantella.exe. Do this if you're experiencing synchronization issues.")
        debug.MessageBox("You can toggle on or off the perk that allows the extra conversation option. Do this if you're experiencing conflicts with other mods such as Quick Trade or What's your name.")
        debug.MessageBox("You can turn the microphone on or off here. You can only use text responses if you turn the microphone OFF")
        debug.MessageBox("Finally you can reset all the settings and hotkeys to their default values with 'Reset default settings'.")
        showHolotapeSettingsTutorial=false
    endif
Endfunction

Function doHotkeysTutorial()
    if tutorialActivated && showHolotapeSettingsTutorial && !isFO4VR
        debug.MessageBox("To change the hotkeys you have to enter scan codes numbers. For example :'H' is 72. 'G' is 71. The complete list is in the holotape options of this submenu. ")
        debug.MessageBox("Text response will only work if the microphone is OFF.")
        debug.MessageBox("The initiate conversation button works by tracking the player crossshair and will only work if the crosshair event tracking is on (see event submenu)")
        debug.MessageBox("Game events are discrete blocks of information that you can send to the AI without having it respond immediately. You can use it to narrate game events out of character.")
        debug.MessageBox("Text/Vision response will take a screenshot and send your response to the LLM at the same time (require vision to be turned on and a vision capable LLM AI)")
        debug.MessageBox("Mantella Vision(screenshot) immedidately takes a screenshot, but that screenshot is only sent to the AI when you respond.")
        showHotkeysTutorial=false
    endif
EndFunction

Function doHTTPTutorial()
    if tutorialActivated && showHTTPSettingsTutorial
        debug.MessageBox("Here you can change the HTTP port for Mantella. This is only necessary if you're having firewall or using other programs that require port 4999")
        debug.MessageBox("You have to select a number between 1 and 65535. High numbers have a better chance of being unused.")
        debug.MessageBox("Keep in mind that this setting needs to be set in the Mantella.exe as well under the 'Others' tab in the advanced option.")
        showHTTPSettingsTutorial=false
    endif
EndFunction

Function    showRadiantSettingsTutorial()
    if tutorialActivated && showRadiantSettingsTutorial
        debug.MessageBox("Turn ON radiant dialogue to have NPCs start conversations between themselves at set intervals. Keep in mind this will use tokens from your AI subscription service")
        debug.MessageBox("You can jump in a radiant conversation at any time by using the usual conversation activation methods.")
        debug.MessageBox("you can adjust the frequency and distance at which at conversation will occuer (distance based on player and nearest eligible NPCs).")
        showRadiantSettingsTutorial=false
    endif
EndFunction

Function    showVisionSettingsTutorial()
    if tutorialActivated && showVisionSettingsTutorial
        debug.MessageBox("These options allow the AI to see what you see. You must be using a vision enabled LLM for this to work (refer to the description of the model in the Mantella.exe web interface)")
        debug.MessageBox("Turning on automatic vision will send a screenshot of the player view  to the AI at the time of the player's response.")
        debug.MessageBox("To accelerate response speed and dimish token costs, try reducing the resolution of the image or choosing a lower resize value.")
        debug.MessageBox("Visions hints will send the names of the NPCs in the player's field of view at the time of the image capture to help it roleplay better.")
        if !isFO4VR
            debug.MessageBox("You can also set hotkeys to capture images to send to the AI in the hotkey submenu.")
        endif
        showVisionSettingsTutorial = false
    endif
EndFunction

Function    showNPCActionsTutorial()
    if tutorialActivated && showNPCActionsTutorial
        debug.MessageBox("You can choose multiple additional actions in this tab.")
        debug.MessageBox("'NPC aggro' allow NPCs to get offended by your comments which means they might attack you. You can then beg for forgiveness to get them to stop.")
        debug.MessageBox("'NPC follow' allow NPCs to become your teammates for the duration fo the conversation.")
        debug.MessageBox("'NPC inventory' allow NPCs to show you their inventory when trading is being discussed.")
        debug.MessageBox("NPC aggro, follow, openInventory all need to be enabled in Mantella.exe to work as intended, see the 'other' tab in the browser interface.")
        debug.MessageBox("NPC stay in place does exactly what the name implies, it prevents the NPC from moving during the conversation (will not impact followers)")
        showNPCActionsTutorial = false
    endif
EndFunction

Function    showEventTrackingTutorial()
    if tutorialActivated && showEventTrackingTutorial
        debug.MessageBox("In here you can turn ON/OFF events that Mantella tracks. The player and NPC events will  be sent to the AI")
        debug.MessageBox("Player events are things like the player does like picking up objects, sleeping, sitting, firing their weapon, getting hit, chaning locations, etc.")
        debug.MessageBox("NPCs events are similar and will apply to the NPCs in the conversation. They also include entering combat & commands given to the NPC through the FO4 interface.")
        debug.MessageBox("Mantella will only track a maximum number of actions. This can be adjusted in the web interface.")
        debug.MessageBox("Considering turning event tracking OFF if you notice the AI getting confused by the game's feedback.")
        if !isFO4VR
            debug.MessageBox("The Crosshair tracking is used for the Initiate Conversation hotkey. It needs to be turned on for that key to work.")
        endif
        showEventTrackingTutorial = false
    endif
EndFunction

Function    showConversationTimeoutTutorial()
    if tutorialActivated && showConversationTimeoutTutorial
        debug.MessageBox("In here you can set how long Mantella will stay in listening mode before timing out.")
        debug.MessageBox("Consider increasing the value if you often see the 'HTTP Timeout' notification after periods of silence.")
        showConversationTimeoutTutorial = false
    endif
EndFunction
