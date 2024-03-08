Scriptname MantellaRepository extends Quest
Import SUP_F4SE
int property textkeycode auto
string property textinput auto
;endFlagMantellaConversationOne exists to prevent conversation loops from getting stuck on NPCs if Mantella crashes or interactions gets out of sync
bool property endFlagMantellaConversationOne auto
bool property radiantEnabled auto
bool property notificationsSubtitlesEnabled auto
float property radiantDistance auto
float property radiantFrequency auto

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

Function ResetEventSpamBlockers()
    EventFireWeaponSpamBlocker=false
    WeaponFiredCount=0
    EventRadiationDamageSpamBlocker=false
Endfunction

Function StopConversations()
    endFlagMantellaConversationOne = True
    Utility.Wait(0.5)
    endFlagMantellaConversationOne = False
EndFunction

Event OnInit()
    ;change the below this is for debug only
    textkeycode=89
    RegisterForKey(textkeycode)
    radiantEnabled = true
    radiantDistance = 20
    radiantFrequency = 10
    notificationsSubtitlesEnabled = true
    ;Player tracking variables below
    playerTrackingOnItemAdded = true
    playerTrackingOnItemRemoved = true
    playerTrackingOnHit = true
    playerTrackingOnLocationChange = true
    playerTrackingOnObjectEquipped = true
    playerTrackingOnObjectUnequipped = true
    playerTrackingOnSit = true
    playerTrackingOnGetUp = true
    playerTrackingFireWeapon = true
    playerTrackingRadiationDamage=true
    
    ;Target tracking variables below
    targetTrackingItemAdded = true 
    targetTrackingItemRemoved = true
    targetTrackingOnHit = true
    targetTrackingOnCombatStateChanged = true
    targetTrackingOnObjectEquipped = true
    targetTrackingOnObjectUnequipped = true
    targetTrackingOnSit = true
    targetTrackingOnGetUp = true
    targetTrackingCompleteCommands=true
    targetTrackingGiveCommands=true

EndEvent

Function reloadKeys()
    ;called at player load
    setDialogueHotkey(textkeycode)
Endfunction

Event Onkeydown(int keycode)
    if (keycode == textkeycode) && !SUP_F4SE.IsMenuModeActive()
        String playerResponse = "False"
        playerResponse = SUP_F4SE.ReadStringFromFile("_mantella_text_input_enabled.txt",0,2) 
        if playerResponse == "True" 
            ;Debug.Notification("Forcing Conversation Through Hotkey")
            OpenTextMenu()
        endIf
    endif
Endevent

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    if (asMenuName== "PipboyMenu")
        if !abOpening
	        OpenHotkeyPrompt()
        endif
    endif
endEvent

function setDialogueHotkey(int keycode)
    unRegisterForKey(textkeycode)
    textkeycode = keycode
    RegisterForKey(textkeycode)
endfunction

function OpenTextMenu()
    TIM:TIM.Open(1,"Enter Mantella text dialogue","", 2, 250)
    RegisterForExternalEvent("TIM::Accept","SetTextInput")
    RegisterForExternalEvent("TIM::Cancel","NoTextInput")
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

function OpenHotkeyPrompt()
    
    TIM:TIM.Open(1,"Enter the keycode for the dialogue hotkey","", 0, 3)
    RegisterForExternalEvent("TIM::Accept","TIMSetDialogueHotkeyInput")
    RegisterForExternalEvent("TIM::Cancel","TIMNoDialogueHotkeyInput")
    UnregisterForMenuOpenCloseEvent("PipboyMenu")
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

Function TIMSetDialogueHotkeyInput(string keycode)
    ;Debug.notification("This text input was entered "+ text)
    UnRegisterForExternalEvent("TIM::Accept")
    UnRegisterForExternalEvent("TIM::Cancel")
    setDialogueHotkey(keycode as int)
EndFunction
    
Function TIMNoDialogueHotkeyInput(string keycode)
    ;Debug.notification("Text input cancelled")
    UnRegisterForExternalEvent("TIM::Accept")
    UnRegisterForExternalEvent("TIM::Cancel")
EndFunction

Function SetTextInput(string text)
    ;Debug.notification("This text input was entered "+ text)
    UnRegisterForExternalEvent("TIM::Accept")
    UnRegisterForExternalEvent("TIM::Cancel")
    textinput = text
    ProcessDialogue(textinput)
EndFunction
    ;
Function NoTextInput(string text)
    ;Debug.notification("Text input cancelled")
    UnRegisterForExternalEvent("TIM::Accept")
    UnRegisterForExternalEvent("TIM::Cancel")
    textinput = ""
EndFunction

Function ProcessDialogue (string text)
    if text != ""
        writePlayerState()
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
