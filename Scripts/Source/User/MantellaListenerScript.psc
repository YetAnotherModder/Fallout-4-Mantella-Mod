Scriptname MantellaListenerScript extends ReferenceAlias
; ---------------------------------------------
; KGTemplates:GivePlayerItemsOnModStart.psc - by kinggath
; ---------------------------------------------
; Reusage Rights ------------------------------
; You are free to use this script or portions of it in your own mods, provided you give me credit in your description and maintain this section of comments in any released source code (which includes the IMPORTED SCRIPT CREDIT section to give credit to anyone in the associated Import scripts below).
; 
; Warning !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Do not directly recompile this script for redistribution without first renaming it to avoid compatibility issues with the mod this came from.
; 
; IMPORTED SCRIPT CREDITS
; N/A
; ---------------------------------------------

Import F4SE
Spell property MantellaSpell auto
Actor property PlayerRef auto
Weapon property MantellaGun auto
Holotape property MantellaSettingsHolotape auto
Quest Property MantellaActorList  Auto  
ReferenceAlias Property PotentialActor1  Auto  
ReferenceAlias Property PotentialActor2  Auto  
MantellaRepository property repository auto
MantellaConversation property conversation auto
Keyword Property AmmoKeyword Auto Const
GlobalVariable property MantellaRadiantEnabled auto
GlobalVariable property MantellaRadiantDistance auto
GlobalVariable property MantellaRadiantFrequency auto
int RadiantFrequencyTimerID=1
int CleanupconversationTimer=2
Float meterUnits = 78.74
Worldspace PrewarWorldspace
bool itemsGiven

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Initialization events and functions  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Event OnInit ()
	PrewarWorldspace = Game.GetFormFromFile(0x000A7FF4, "Fallout4.esm") as Worldspace
	TryToGiveItems()
    LoadMantellaEvents()
EndEvent

Event OnPlayerTeleport()
    if !itemsGiven
	    TryToGiveItems()
    endif
    If !(conversation.IsRunning())
        Actor[] ActorsInCell = repository.ScanCellForActors(false, false)
        repository.DispelAllMantellaMagicEffectsFromActors(ActorsInCell)
    endif
EndEvent

Function TryToGiveItems()
	Worldspace PlayerWorldspace = Game.GetPlayer().GetWorldspace()
	if(PlayerWorldspace == PrewarWorldspace || PlayerWorldspace == None)
		;RegisterForPlayerTeleport() ;not nessary to interact with this anymore as it's handled in LoadMantellaEvents()
	else
		;UnregisterForPlayerTeleport()  ;not nessary to interact with this anymore as it's handled in LoadMantellaEvents()
		PlayerRef.AddItem(MantellaGun, 1, false)
        PlayerRef.AddItem(MantellaSettingsHolotape, 1, false)
        itemsGiven=true
        Utility.Wait(0.5)
        ;debug.messagebox("OnInit : Starting timer "+RadiantFrequencyTimerID+" for "+repository.radiantFrequency)
        StartTimer(MantellaRadiantFrequency.getValue(),RadiantFrequencyTimerID)   
	endif
EndFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Events and functions at player load  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Event OnPlayerLoadGame()
    LoadMantellaEvents()
EndEvent

Function LoadMantellaEvents()
    
    repository.reloadKeys()
    registerForPlayerEvents()
    ;Will clean up all all conversation loops if they're still occuring
    ; repository.endFlagMantellaConversationOne = True    
    If (conversation.IsRunning())   
        Actor[] ActorsInCell = repository.ScanCellForActors(false, false)
        repository.DispelAllMantellaMagicEffectsFromActors(ActorsInCell)
        conversation.conversationIsEnding=false  ;just here as a safety to prevent locking out the player out of initiating conversations
        conversation.EndConversation();Should there still be a running conversation after a load, end it
        StartTimer(5,CleanupconversationTimer) ;Start a timmer to make second hard reset if conversation is still running after
    EndIf
        Worldspace PlayerWorldspace = PlayerRef.GetWorldspace()
    if(PlayerWorldspace != PrewarWorldspace && PlayerWorldspace != None)
        StartTimer(MantellaRadiantFrequency.getValue(),RadiantFrequencyTimerID)   
    endif
    CheckGameVersionForMantella()
Endfunction

Function CheckGameVersionForMantella()
    string MantellaVersion="Mantella 0.9.0"
    if  !IsF4SEProperlyInstalled() 
        debug.messagebox("F4SE not properly installed, Mantella will not work correctly")
    endif
    repository.currentFO4version = Debug.GetVersionNumber()
    if repository.currentFO4version != "1.10.163.0" && repository.currentFO4version != "1.2.72.0"
        debug.messagebox("The current FO4 version doesn't support Mantella.")
    elseif repository.currentFO4version == "1.10.163.0"
        debug.notification("Currently running "+ MantellaVersion)
    elseif repository.currentFO4version == "1.2.72.0"
        repository.isFO4VR = true
        debug.notification("Currently running "+ MantellaVersion+" VR")
    endif
    int currentSUPversion
    currentSUPversion = repository.ReturnSUPF4SEVersion()
    if currentSUPversion == 0
        debug.messagebox("SUP_F4SE not properly installed, Mantella will not work correctly")
    else
        debug.notification("Currently running SUP_F4SE "+currentSUPversion)
    endif
Endfunction

bool Function IsF4SEProperlyInstalled() 
    int major = F4SE.GetVersion()
    int minor = F4SE.GetVersionMinor()
    int beta = F4SE.GetVersionBeta()
    int release = F4SE.GetVersionRelease()

    return (major != 0 || minor != 0 || beta != 0 || release != 0)
EndFunction

Function registerForPlayerEvents()
        ;resets AddInventoryEventFilter, necessary for OnItemAdded & OnItemRemoved to work properl
        RemoveAllInventoryEventFilters()
        AddInventoryEventFilter(none) 
        ;Register for player sleep events
        RegisterForPlayerSleep()
        ;resets RegisterForHitEvent & RegisterForRadiationDamageEvent at load, necessary for Onhit to work properly
        UnregisterForAllHitEvents()
        RegisterForHitEvent(PlayerRef)
        UnregisterForAllRadiationDamageEvents()
        RegisterForRadiationDamageEvent(PlayerRef)
        RegisterForPlayerTeleport()
Endfunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Timer management  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Event Ontimer( int TimerID)
   ;debug.notification("timer "+RadiantFrequencyTimerID+" finished counting from "+repository.radiantFrequency)
    if TimerID==RadiantFrequencyTimerID
        if MantellaRadiantEnabled.GetValue()==1.000
            if !conversation.IsRunning()
                ;MantellaActorList taken from this tutorial:
                ;http://skyrimmw.weebly.com/skyrim-modding/detecting-nearby-actors-skyrim-modding-tutorial
                MantellaActorList.start()
                ; if both actors found
                if (PotentialActor1.GetReference() as Actor) && (PotentialActor2.GetReference() as Actor)
                    Actor Actor1 = PotentialActor1.GetReference() as Actor
                    Actor Actor2 = PotentialActor2.GetReference() as Actor

                    float distanceToClosestActor = game.getplayer().GetDistance(Actor1)
                    float maxDistance = ConvertMeterToGameUnits(repository.radiantDistance)
                    if distanceToClosestActor <= maxDistance
                        String Actor1Name = Actor1.getdisplayname()
                        String Actor2Name = Actor2.getdisplayname()
                        float distanceBetweenActors = Actor1.GetDistance(Actor2)

                        ;TODO: make distanceBetweenActors customisable
                        if (distanceBetweenActors <= 1000)
                            ;have spell casted on Actor 1 by Actor 2
                            MantellaSpell.Cast(Actor2 as ObjectReference, Actor1 as ObjectReference)
                        else
                            ;TODO: make this notification optional
                            ;Debug.Notification("Radiant dialogue attempted. No NPCs available")
                        endIf
                    else
                        ;TODO: make this notification optional
                        ;Debug.Notification("Radiant dialogue attempted. NPCs too far away at " + ConvertGameUnitsToMeter(distanceToClosestActor) + " meters")
                        ;Debug.Notification("Max distance set to " + repository.radiantDistance + "m in Mantella MCM")
                    endIf
                else
                    ;Debug.Notification("Radiant dialogue attempted. No NPCs available")
                endIf
    
                MantellaActorList.stop()
            endIf
        endIf
      StartTimer(MantellaRadiantFrequency.getValue(),RadiantFrequencyTimerID)   
    elseif TimerID==CleanupconversationTimer 
        if conversation.IsRunning() ;attempts to make a hard reset of the conversation if it's still going on for some reason
            ;previous conversation detected, forcing conversation to end.
            debug.notification("Previous conversation detected on load : Cleaning up.")
            Conversation.CleanupConversation()
            conversation.conversationIsEnding = false
        endif
    endif
EndEvent

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Game event listeners  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    if Repository.playerTrackingOnItemAdded
        string sourceName = akSourceContainer.getbaseobject().getname()
        if sourceName != "Power Armor" ;to prevent gameevent spam from the player entering power armors
            string itemName = akBaseItem.GetName()
            string itemPickedUpMessage = ""
            if itemName == "Powered Armor Frame" 
                itemPickedUpMessage = "The player entered power armor."
            else
                if sourceName != "" 
                    itemPickedUpMessage = "The player picked up " + itemName + " from " + sourceName + "."
                Else
                    itemPickedUpMessage = "The player picked up " + itemName + "."
                endIf
            Endif
            conversation.AddIngameEvent(itemPickedUpMessage)
        endif
    endif
EndEvent

Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
    if Repository.playerTrackingOnItemRemoved
        string destName = akDestContainer.getbaseobject().getname()
        if destName != "Power Armor" ;to prevent gameevent spam from the player exiting power armors 
            string itemName = akBaseItem.GetName()
            string itemDroppedMessage = ""
            if itemName == "Powered Armor Frame" 
                itemDroppedMessage = "The player exited power armor."
            else
                if destName != "" 
                    itemDroppedMessage = "The player placed " + itemName + " in/on " + destName + "."
                    conversation.AddIngameEvent(itemDroppedMessage)
                Elseif akBaseItem.HasKeyword(AmmoKeyword)
                    ;filtering out ammo events to prevent spam and confusion for the LLM
                else
                    itemDroppedMessage = "The player dropped " + itemName + "."
                    conversation.AddIngameEvent(itemDroppedMessage)
                endIf
            Endif
            
        endif
    endif
endEvent



String lastHitSource = ""
String lastAggressor = ""
Int timesHitSameAggressorSource = 0
Event OnHit(ObjectReference akTarget, ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked, string apMaterial)
    if repository.playerTrackingOnHit
        string aggressor = akAggressor.getdisplayname()
        string hitSource = akSource.getname()

        ; avoid writing events too often (continuous spells record very frequently)
        ; if the actor and weapon hasn't changed, only record the event every 5 hits
        if ((hitSource != lastHitSource) && (aggressor != lastAggressor)) || (timesHitSameAggressorSource > 5)
            lastHitSource = hitSource
            lastAggressor = aggressor
            timesHitSameAggressorSource = 0

            if (hitSource == "None") || (hitSource == "")
                ;Debug.MessageBox(aggressor + " punched the player.")
                conversation.AddIngameEvent(aggressor + " punched the player.")
            else
                if aggressor == PlayerRef.getdisplayname()
                    if playerref.getleveledactorbase().getsex() == 0
                        conversation.AddIngameEvent("The player hit himself with " + hitSource+".")
                    else
                        conversation.AddIngameEvent("The player hit herself with " + hitSource+".")
                    endIf
                else
                    conversation.AddIngameEvent(aggressor + " hit the player with " + hitSource+".")
                endif
            endIf
        else
            timesHitSameAggressorSource += 1
        endIf
    endif
    ;RegisterForHitEvent necessary for Onhit to work properly
    RegisterForHitEvent(PlayerRef)
EndEvent

Event OnLocationChange(Location akOldLoc, Location akNewLoc)
    ; check if radiant dialogue is playing, and end conversation if the player leaves the area
    If (conversation.IsRunning() && !conversation.IsPlayerInConversation())
        conversation.EndConversation()
    EndIf

    if repository.playerTrackingOnLocationChange
        String currLoc = (akNewLoc as form).getname()
        if currLoc == ""
            currLoc = "Commonwealth"
        endIf
        ;Debug.MessageBox("Current location is now " + currLoc)
        conversation.AddIngameEvent("Current location is now " + currLoc+ ".")
    endif
endEvent

Event OnItemEquipped(Form akBaseObject, ObjectReference akReference)
    if repository.playerTrackingOnObjectEquipped
        string itemEquipped = akBaseObject.getname()
        string itemenchant = akBaseObject.GetEnchantment().getname()
        if itemenchant != "" ;filtering out enchantments to avoid spamming the LLM with confusing feedback
            ;Debug.MessageBox("The player equipped " + itemEquipped)
            if itemEquipped != "Mantella"
                conversation.AddIngameEvent("The player equipped " + itemEquipped + ".")
            endif
        endif
    endif
endEvent


Event OnItemUnequipped (Form akBaseObject, ObjectReference akReference)
    if repository.playerTrackingOnObjectUnequipped
        string itemUnequipped = akBaseObject.getname()
        ;Debug.MessageBox("The player unequipped " + itemUnequipped)
        if itemUnequipped != "Mantella Enchantment" && itemUnequipped != "Mantella"
            conversation.AddIngameEvent("The player unequipped " + itemUnequipped + ".")
        Endif
    endif
endEvent

Event OnSit(ObjectReference akFurniture)
    if repository.playerTrackingOnSit
        ;Debug.MessageBox("The player sat down.")
        String furnitureName = akFurniture.getbaseobject().getname()
        if furnitureName != "Power Armor"
            conversation.AddIngameEvent("The player rested on / used a(n) "+furnitureName+ ".")
        endif
    endif
endEvent


Event OnGetUp(ObjectReference akFurniture)
    if repository.playerTrackingOnGetUp
        ;Debug.MessageBox("The player stood up.")
        String furnitureName = akFurniture.getbaseobject().getname()
        if furnitureName != "Power Armor"
            conversation.AddIngameEvent("The player stood up from a(n) "+furnitureName+ ".")
        endif    
    endif
EndEvent


Event OnDying(Actor akKiller)
    If (conversation.IsRunning())
        conversation.EndConversation()
    EndIf
EndEvent

string lastWeaponFired =""
Event OnPlayerFireWeapon(Form akBaseObject)
    if repository.playerTrackingFireWeapon 
        string weaponName=akBaseObject.getname()
        if weaponName!="Mantella"
            if lastWeaponFired!=akBaseObject && !repository.EventFireWeaponSpamBlocker
                if weaponName!=""
                    conversation.AddIngameEvent("The player used their "+weaponName+" weapon.")
                else
                    conversation.AddIngameEvent("The player used an unarmed attack.")
                endif
                lastWeaponFired=akBaseObject
                repository.WeaponFiredCount+=1
                if repository.WeaponFiredCount>=3
                    repository.EventFireWeaponSpamBlocker=true
                    repository.WeaponFiredCount=0
                endif
            endif    
        endif
    endif
endEvent

Event OnRadiationDamage(ObjectReference akTarget, bool abIngested)
    if repository.playerTrackingRadiationDamage
        if ( abIngested )
            conversation.AddIngameEvent("The player consumed irradiated sustenance.")
        elseif repository.EventRadiationDamageSpamBlocker!=true
            conversation.AddIngameEvent("The player took damage from radiation exposure.")
            repository.EventRadiationDamageSpamBlocker=true
        endif
    endif
    RegisterForRadiationDamageEvent(PlayerRef)
EndEvent

float sleepstartTime
Event OnPlayerSleepStart(float afSleepStartTime, float afDesiredSleepEndTime, ObjectReference akBed)
    sleepstartTime=afSleepStartTime
EndEvent

Event OnPlayerSleepStop(bool abInterrupted, ObjectReference akBed)
    if repository.playerTrackingSleep
        float timeSlept= Utility.GetCurrentGameTime()-sleepstartTime
        string sleepMessage
        string bedName=akBed.getbaseobject().getname()
        string messagePrefix
        if abInterrupted
            messagePrefix="The player's sleep in a "+bedName+" was interrupted after "
        else
            messagePrefix="The player slept in a "+bedName+" for "
        endif
        ;if timeSlept>1
        ;    int daysPassed=Math.floor(timeSlept)
        ;    float remainingDayFraction=(timeSlept- daysPassed)
        ;    int hoursPassed=Math.Floor(remainingDayFraction*24)
        ;    sleepMessage=messagePrefix+daysPassed+" days and "+hoursPassed+" hours."
        ;    SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", sleepMessage, 2)
        ;Else
            int hoursPassed=Math.Floor(timeSlept*24)
            sleepMessage=messagePrefix+hoursPassed+" hours."
            conversation.AddIngameEvent(sleepMessage)
        ;endif
    endif
EndEvent

Event OnCripple(ActorValue akActorValue, bool abCrippled)
    if repository.playerTrackingCripple
        string messageSuffix=" is crippled."
        if !abCrippled
            messageSuffix=" is now healed."
        endif
        if akActorValue
            conversation.AddIngameEvent("The player's "+akActorValue.getname()+messageSuffix)
        endif
    endif

EndEvent
Event OnPlayerHealTeammate(Actor akTeammate)
    if repository.playerTrackingHealTeammate
        string messageEvent="The player has healed "+akTeammate.getdisplayname()+"."
        conversation.AddIngameEvent(messageEvent)
    endif
EndEvent

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Math functions  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Float Function ConvertMeterToGameUnits(Float meter)
    Return Meter * meterUnits
EndFunction

Float Function ConvertGameUnitsToMeter(Float gameUnits)
    Return gameUnits / meterUnits
EndFunction