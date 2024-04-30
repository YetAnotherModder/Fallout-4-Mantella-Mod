Scriptname MantellaRepository extends Quest
Import SUP_F4SE
Import TIM:TIM
int property textkeycode auto
int property gameEventkeycode auto
int property startConversationkeycode auto
string property textinput auto
;endFlagMantellaConversationOne exists to prevent conversation loops from getting stuck on NPCs if Mantella crashes or interactions gets out of sync
bool property endFlagMantellaConversationOne auto
bool property radiantEnabled auto
bool property notificationsSubtitlesEnabled auto
float property radiantDistance auto
float property radiantFrequency auto
int property MenuEventSelector auto
bool property allowAggro auto
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

Function ResetEventSpamBlockers()
    EventFireWeaponSpamBlocker=false
    WeaponFiredCount=0
    EventRadiationDamageSpamBlocker=false
Endfunction

Function StopConversations()
    endFlagMantellaConversationOne = True
    SUP_F4SE.WriteStringToFile("_mantella_end_conversation.txt", "True", 0)
    Utility.Wait(0.5)
    endFlagMantellaConversationOne = False
    SUP_F4SE.WriteStringToFile("_mantella_end_conversation.txt", "False", 0)
    UnregisterForMenuOpenCloseEvent("PipboyMenu")
EndFunction

Function ToggleActivatePerk()
    Actor PlayerRef = Game.GetPlayer()
    If (PlayerRef.HasPerk(ActivatePerk))
		PlayerRef.RemovePerk(ActivatePerk)
	Else
        PlayerRef.AddPerk(ActivatePerk, False)
	EndIf
EndFunction

Event OnInit()
    reinitializeVariables()
    ;int ActorFilter=  65
    ;Var[] MyCrosshairRefFilter = new Var[4]
    ;    MyCrosshairRefFilter[0] = true
    ;    MyCrosshairRefFilter[1] = None
    ;    MyCrosshairRefFilter[2] = None
    ;    MyCrosshairRefFilter[3] = ActorFilter
 EndEvent

Function CrosshairRefCallback(bool bCrosshairOn, ObjectReference ObjectRef, int Type)
    ;debug.notification("Object ref is "+ObjectRef.getdisplayname())
    if bCrosshairOn
        if Type==65 ;checks if type is actor
            CrosshairActor= ObjectRef as actor
        ;debug.notification("Object ref is "+ObjectRef.getdisplayname())
        ;debug.notification(" type is "+Type)
        endif
    endif
Endfunction

Function reinitializeVariables()
    ;change the below this is for debug only
    textkeycode=72
    RegisterForKey(textkeycode)
    gameEventkeycode=89
    RegisterForKey(gameEventkeycode)
    startConversationkeycode=72
    RegisterForKey(startConversationkeycode)
    radiantEnabled = true
    radiantDistance = 20
    radiantFrequency = 10
    notificationsSubtitlesEnabled = true
    allowAggro = false
    allowFollow = false
    MenuEventSelector=0
    togglePlayerEventTracking(true)
    toggleTargetEventTracking(true)
    RegisterForOnCrosshairRefChange()
    Actor PlayerRef = Game.GetPlayer()
    If !(PlayerRef.HasPerk(ActivatePerk))
        PlayerRef.AddPerk(ActivatePerk, False)
    Endif
EndFunction




Function togglePlayerEventTracking(bool bswitch)
    ;Player tracking variables below
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
EndFunction

Function toggleAllowAggro(bool bswitch)
    allowAggro = bswitch
EndFunction

Function toggleAllowFollow(bool bswitch)
    allowFollow = bswitch
EndFunction

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
            Debug.notification("Current start conversationhotkey is "+startConversationkeycode)
        ElseIf (true)
            Debug.notification("Current start conversation hotkey is unassigned")
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
    endif
EndFunction


Function reloadKeys()
    ;called at player load
    setDialogueHotkey(textkeycode, "Dialogue")
    setDialogueHotkey(gameEventkeycode, "GameEvent")

Endfunction

Event Onkeydown(int keycode)
    if !SUP_F4SE.IsMenuModeActive()
        if keycode == textkeycode

            String playerResponse = "False"
            playerResponse = SUP_F4SE.ReadStringFromFile("_mantella_text_input_enabled.txt",0,2) 
            if playerResponse == "True" 
                ;Debug.Notification("Forcing Conversation Through Hotkey")
                OpenTextMenu("playerResponseTextEntry")
            ElseIf playerResponse != "True" 
                
                String radiantDialogue = SUP_F4SE.ReadStringFromFile("_mantella_radiant_dialogue.txt",0,1) 

                ;String currentActor = MiscUtil.ReadFromFile("_mantella_current_actor.txt") as String
                String activeActors = SUP_F4SE.ReadStringFromFile("_mantella_active_actors.txt",0,10) 
                String actorName = CrosshairActor.GetDisplayName()
                int index = SUPStringFind(activeActors, actorName,0, 1)
                float distanceFromConversationTarget = Game.GetPlayer().GetDistance(CrosshairActor)
                if distanceFromConversationTarget<1500
                ; if actor not already loaded or player is interrupting radiant dialogue
                    if (index == -1) || (radiantDialogue == "True")
                        if radiantDialogue != "True"
                            debug.notification("Attempting to start conversation with "+CrosshairActor.GetDisplayName())
                        else 
                            debug.notification("Adding player to radiant conversation with "+CrosshairActor.GetDisplayName())
                        endif
                        MantellaSpell.cast(Game.GetPlayer(), CrosshairActor)
                        Utility.Wait(0.5)
                    endif
                endif
            endIf
        ElseIf keycode == gameEventkeycode
            OpenTextMenu("gameEventEntry")
        endif
    endif
Endevent

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    if (asMenuName== "PipboyMenu") && MenuEventSelector==1 && !abOpening
	    OpenHotkeyPrompt("playerInputTextHotkey")
    elseif (asMenuName== "PipboyMenu") && MenuEventSelector==2 && !abOpening
        StopConversations()
        debug.MessageBox("Conversations stopped. Restart Mantella.exe to complete the process.")
    elseif(asMenuName== "PipboyMenu") && MenuEventSelector==3 && !abOpening
	    OpenHotkeyPrompt("gameEventHotkey")  
    elseif(asMenuName== "PipboyMenu") && MenuEventSelector==4 && !abOpening
	    OpenHotkeyPrompt("startConversationHotKey")  
    endif
endEvent

function setDialogueHotkey(int keycode, string keyType)
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
    endif
endfunction

Function RegisterForOnCrosshairRefChange()
    ;disable for VR
    RegisterForSUPEvent("OnCrosshairRefChange", self as Form, "MantellaRepository", "CrosshairRefCallback",true,true,false, 0) 
    allowCrosshairTracking=true
EndFunction

Function UnRegisterForOnCrosshairRefChange()
    ;disable for VR
    UnregisterForAllSUPEvents("OnCrosshairRefChange", self as Form,true, "MantellaRepository", "CrosshairRefCallback")
    allowCrosshairTracking=false
EndFunction

function OpenTextMenu(string entryType)
    ;disable for VR
    if entryType == "playerResponseTextEntry"
        TIM:TIM.Open(1,"Enter Mantella text dialogue","", 2, 250)
        RegisterForExternalEvent("TIM::Accept","SetPlayerResponseTextInput")
        RegisterForExternalEvent("TIM::Cancel","NoTextInput")
    elseif entryType == "gameEventEntry"
        TIM:TIM.Open(1,"Enter Mantella a new game event log","", 2, 250)
        RegisterForExternalEvent("TIM::Accept","SetGameEventTextInput")
        RegisterForExternalEvent("TIM::Cancel","NoTextInput")
    endif
    ;
    ; Function SetFrequency(string freq)
    ;   Debug.MessageBox("frequency will set at "+ freq)
    ;   UnRegisterForExternalEvent("TIM::Accept")
    ;   UnRegisterForExternalEvent("TIM::Cancel")
    ; EndFunction
    ;
    ; Function NoSetFrequency(string freq)
    ;   Debug.MessageBox("input frequency was aborted at "+ freq)
    ;   UnRegisterForExternalEvent("TIM::Accept")
    ;   UnRegisterForExternalEvent("TIM::Cancel")
    ; EndFunction

endfunction

Function SetPlayerResponseTextInput(string text)
    ;Debug.notification("This text input was entered "+ text)
    UnRegisterForExternalEvent("TIM::Accept")
    UnRegisterForExternalEvent("TIM::Cancel")
    textinput = text
    ProcessDialogue(textinput)
EndFunction
    
Function SetGameEventTextInput(string text)
    ;Debug.notification("This text input was entered "+ text)
    UnRegisterForExternalEvent("TIM::Accept")
    UnRegisterForExternalEvent("TIM::Cancel")
    text = text
    SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", text,2)

EndFunction

Function NoTextInput(string text)
    ;Debug.notification("Text input cancelled")
    UnRegisterForExternalEvent("TIM::Accept")
    UnRegisterForExternalEvent("TIM::Cancel")
    textinput = ""
EndFunction


function OpenHotkeyPrompt(string entryType)
    ;disable for VR
    if entryType == "playerInputTextHotkey"
        TIM:TIM.Open(1,"Enter the DirectX Scancode for the dialogue hotkey","", 0, 3)
        RegisterForExternalEvent("TIM::Accept","TIMSetDialogueHotkeyInput")
        RegisterForExternalEvent("TIM::Cancel","TIMNoDialogueHotkeyInput")
        UnregisterForMenuOpenCloseEvent("PipboyMenu")
    elseif entryType == "gameEventHotkey"
        TIM:TIM.Open(1,"Enter the DirectX Scancode for the game event hotkey","", 0, 3)
        RegisterForExternalEvent("TIM::Accept","TIMGameEventHotkeyInput")
        RegisterForExternalEvent("TIM::Cancel","TIMNoDialogueHotkeyInput")
        UnregisterForMenuOpenCloseEvent("PipboyMenu")
    elseif entryType == "startConversationHotKey"
        TIM:TIM.Open(1,"Enter the DirectX Scancode for the start converstion hotkey","", 0, 3)
        RegisterForExternalEvent("TIM::Accept","TIMStartConversationHotkeyInput")
        RegisterForExternalEvent("TIM::Cancel","TIMNoDialogueHotkeyInput")
        UnregisterForMenuOpenCloseEvent("PipboyMenu")
    endif
    ; Function SetFrequency(string freq)
    ;   Debug.MessageBox("frequency will set at "+ freq)
    ;   UnRegisterForExternalEvent("TIM::Accept")
    ;   UnRegisterForExternalEvent("TIM::Cancel")
    ; EndFunction
    ;
    ; Function NoSetFrequency(string freq)
    ;   Debug.MessageBox("input frequency was aborted at "+ freq)
    ;   UnRegisterForExternalEvent("TIM::Accept")
    ;   UnRegisterForExternalEvent("TIM::Cancel")
    ; EndFunction
endfunction

Function TIMSetDialogueHotkeyInput(string keycode)
    ;Debug.notification("This text input was entered "+ text)
    UnRegisterForExternalEvent("TIM::Accept")
    UnRegisterForExternalEvent("TIM::Cancel")
    setDialogueHotkey(keycode as int, "Dialogue")
EndFunction
    
Function TIMGameEventHotkeyInput(string keycode)
    ;Debug.notification("This text input was entered "+ text)
    UnRegisterForExternalEvent("TIM::Accept")
    UnRegisterForExternalEvent("TIM::Cancel")
    setDialogueHotkey(keycode as int, "GameEvent")
EndFunction

Function TIMStartConversationHotkeyInput(string keycode)
    ;Debug.notification("This text input was entered "+ text)
    UnRegisterForExternalEvent("TIM::Accept")
    UnRegisterForExternalEvent("TIM::Cancel")
    setDialogueHotkey(keycode as int, "StartConversation")
EndFunction
    

Function TIMNoDialogueHotkeyInput(string keycode)
    ;Debug.notification("Text input cancelled")
    UnRegisterForExternalEvent("TIM::Accept")
    UnRegisterForExternalEvent("TIM::Cancel")
EndFunction

Function ProcessDialogue (string text)
    if text != ""
        ;to be implemented later
        ;writePlayerState()
        SUP_F4SE.WriteStringToFile("_mantella_text_input_enabled.txt", "False", 0)
        SUP_F4SE.WriteStringToFile("_mantella_text_input.txt", textinput, 0)
        ;Debug.notification("Wrote to file "+ textinput)
    endIf
EndFunction

function writePlayerState()
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
        SUP_F4SE.WriteStringToFile("_mantella_player_state.txt", playerState, 0)
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
