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

Import SUP_F4SE
Spell property MantellaSpell auto
Actor property PlayerRef auto
Weapon property MantellaGun auto
Holotape property MantellaSettingsHolotape auto
Quest Property MantellaActorList  Auto  
ReferenceAlias Property PotentialActor1  Auto  
ReferenceAlias Property PotentialActor2  Auto  
MantellaRepository property repository auto
Keyword Property AmmoKeyword Auto Const
GlobalVariable property MantellaRadiantEnabled auto
GlobalVariable property MantellaRadiantDistance auto
GlobalVariable property MantellaRadiantFrequency auto
int RadiantFrequencyTimerID=1
Float meterUnits = 78.74
Worldspace PrewarWorldspace

Event OnInit ()
	PrewarWorldspace = Game.GetFormFromFile(0x000A7FF4, "Fallout4.esm") as Worldspace
	TryToGiveItems()
    LoadMantellaEvents()
EndEvent

Event OnPlayerTeleport()
	TryToGiveItems()
EndEvent


Function TryToGiveItems()
	Worldspace PlayerWorldspace = Game.GetPlayer().GetWorldspace()
	if(PlayerWorldspace == PrewarWorldspace || PlayerWorldspace == None)
		RegisterForPlayerTeleport()
	else
		UnregisterForPlayerTeleport()
		PlayerRef.AddItem(MantellaGun, 1, false)
        PlayerRef.AddItem(MantellaSettingsHolotape, 1, false)
        Utility.Wait(0.5)
        ;debug.messagebox("OnInit : Starting timer "+RadiantFrequencyTimerID+" for "+repository.radiantFrequency)
        StartTimer(MantellaRadiantFrequency.getValue(),RadiantFrequencyTimerID)   
	endif
EndFunction

Float Function ConvertMeterToGameUnits(Float meter)
    Return Meter * meterUnits
EndFunction

Float Function ConvertGameUnitsToMeter(Float gameUnits)
    Return gameUnits / meterUnits
EndFunction

Event OnPlayerLoadGame()
    LoadMantellaEvents()
EndEvent

Function LoadMantellaEvents()
    int currentSUPversion
    currentSUPversion = GetSUPF4SEVersion()
    if currentSUPversion == 0
        debug.messagebox("F4SE or SUP_F4SE not properly installed, Mantella will not work correctly")
    endif
    repository.reloadKeys()
    registerForPlayerEvents()
    ;Will clean up all all conversation loops if they're still occuring
    repository.endFlagMantellaConversationOne = True
    if !SUP_F4SE.ReadStringFromFile("_mantella__fallout4_folder.txt",0,2) 
        SUP_F4SE.WriteStringToFile("_mantella__fallout4_folder.txt", "Set the folder this file is in as your fallout4_folder path in MantellaSoftware/config.ini", 0)
    endif
    Worldspace PlayerWorldspace = PlayerRef.GetWorldspace()
    if(PlayerWorldspace != PrewarWorldspace && PlayerWorldspace != None)
        StartTimer(MantellaRadiantFrequency.getValue(),RadiantFrequencyTimerID)   
    endif
Endfunction

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
Endfunction

Event Ontimer( int TimerID)
   ;debug.notification("timer "+RadiantFrequencyTimerID+" finished counting from "+repository.radiantFrequency)
   if TimerID==RadiantFrequencyTimerID
      if MantellaRadiantEnabled.GetValue()==1.000
         String activeActors = SUP_F4SE.ReadStringFromFile("_mantella_active_actors.txt",0,10)
         ; if no Mantella conversation active
         if activeActors == ""
             ;MantellaActorList taken from this tutorial:
             ;http://skyrimmw.weebly.com/skyrim-modding/detecting-nearby-actors-skyrim-modding-tutorial
             MantellaActorList.start()
             ; if both actors found
             if (PotentialActor1.GetReference() as Actor) && (PotentialActor2.GetReference() as Actor)
                 Actor Actor1 = PotentialActor1.GetReference() as Actor
                 Actor Actor2 = PotentialActor2.GetReference() as Actor
                 ;debug.notification("located potential actors "+Actor1.getdisplayname()+" and "+Actor2.getdisplayname())
                 float distanceToClosestActor = game.getplayer().GetDistance(Actor1)
                 float maxDistance = ConvertMeterToGameUnits(MantellaRadiantDistance.GetValue())
                 if distanceToClosestActor <= maxDistance
                     String Actor1Name = Actor1.getdisplayname()
                     String Actor2Name = Actor2.getdisplayname()
                     float distanceBetweenActors = Actor1.GetDistance(Actor2)
 
                     ;TODO: make distanceBetweenActors customisable
                     if (distanceBetweenActors <= 1000)
                        ;MiscUtil.WriteToFile("_mantella_current_actor_id.txt", actorId, append=false) THIS IS HOW THE FUNCTION LOOKS IN SKYRIM
                        ;SUP_F4SE.WriteStringToFile(string sFilePath,string sText, int iAppend [0 for clean file, 1 for append, 2 for append with new line])
                        SUP_F4SE.WriteStringToFile("_mantella_radiant_dialogue.txt", "True", 0)
                        ;debug.notification("Starting radiant dialogue between "+Actor1.getdisplayname()+" and "+Actor2.getdisplayname())
                         ;have spell casted on Actor 1 by Actor 2
                         MantellaSpell.Cast(Actor2 as ObjectReference, Actor1 as ObjectReference)
 
                         SUP_F4SE.WriteStringToFile("_mantella_character_selected.txt", "False", 0)
                         ;debug.messagebox("MantellaListenerScript:"+Actor2.getdisplayname()+" casting Mantella Spell on "+Actor1.getdisplayname())
                         String character_selected = "False"
                         ;wait for the Mantella spell to give the green light that it is ready to load another actor
                         while character_selected == "False"
                             character_selected = SUP_F4SE.ReadStringFromFile("_mantella_character_selected.txt",0,2) 
                         endWhile
 
                         String character_selection_enabled = "False"
                         while character_selection_enabled == "False"
                             character_selection_enabled = SUP_F4SE.ReadStringFromFile("_mantella_character_selection.txt",0,2) 
                         endWhile
 
                         MantellaSpell.Cast(Actor1 as ObjectReference, Actor2 as ObjectReference)
                         ;debug.messagebox("MantellaListenerScript:"+Actor1.getdisplayname()+" casting Mantella Spell on "+Actor2.getdisplayname())
                     else
                         ;TODO: make this notification optional
                        ; Debug.Notification("Radiant dialogue attempted. No NPCs available")
                     endIf
                 else
                     ;TODO: make this notification optional
                     Debug.Notification("Radiant dialogue attempted. NPCs too far away at " + ConvertGameUnitsToMeter(distanceToClosestActor) + " meters")
                     Debug.Notification("Max distance set to " + repository.radiantDistance + "m in Mantella MCM")
                 endIf
             else
                 Debug.Notification("Radiant dialogue attempted. No NPCs available")
             endIf
 
             MantellaActorList.stop()
         endIf
     endIf

      StartTimer(MantellaRadiantFrequency.getValue(),RadiantFrequencyTimerID)   
   endif
EndEvent


Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    if Repository.playerTrackingOnItemAdded
        string sourceName = akSourceContainer.getbaseobject().getname()
        if sourceName != "Power Armor" ;to prevent gameevent spam from the player entering power armors
            string itemName = akBaseItem.GetName()
            string itemPickedUpMessage = ""
            if itemName == "Powered Armor Frame" 
                itemPickedUpMessage = "The player entered power armor.\n"
            else
                if sourceName != "" 
                    itemPickedUpMessage = "The player picked up " + itemName + " from " + sourceName + ".\n"
                Else
                    itemPickedUpMessage = "The player picked up " + itemName + ".\n"
                endIf
            Endif
            SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", itemPickedUpMessage, 2)
        endif
    endif
EndEvent

Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
    if Repository.playerTrackingOnItemRemoved && !akBaseItem.HasKeyword(AmmoKeyword)
        string destName = akDestContainer.getbaseobject().getname()
        if destName != "Power Armor" ;to prevent gameevent spam from the player exiting power armors 
            string itemName = akBaseItem.GetName()
            string itemDroppedMessage = ""
            if itemName == "Powered Armor Frame" 
                itemDroppedMessage = "The player exited power armor.\n"
            else
                if destName != "" 
                    itemDroppedMessage = "The player placed " + itemName + " in/on " + destName + ".\n"
                Else
                    itemDroppedMessage = "The player dropped " + itemName + ".\n"
                endIf
            Endif
            SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", itemDroppedMessage, 2)
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
                SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", aggressor + " punched the player.\n", 2)
            else
                if aggressor == PlayerRef.getdisplayname()
                    if playerref.getleveledactorbase().getsex() == 0
                        SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", "The player hit himself with " + hitSource+".\n", 2)
                    else
                        SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", "The player hit herself with " + hitSource+".\n", 2)
                    endIf
                else
                    SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", aggressor + " hit the player with " + hitSource+".\n", 2)
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
    String radiant_dialogue_active = SUP_F4SE.ReadStringFromFile("_mantella_radiant_dialogue.txt", 0, 1)
    if radiant_dialogue_active == "True"
        SUP_F4SE.WriteStringToFile("_mantella_end_conversation.txt", "True", 0)
    endIf

    if repository.playerTrackingOnLocationChange
        String currLoc = (akNewLoc as form).getname()
        if currLoc == ""
            currLoc = "Commonwealth"
        endIf
        ;Debug.MessageBox("Current location is now " + currLoc)
        SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", "Current location is now " + currLoc+".\n", 2)
    endif
endEvent

Event OnItemEquipped(Form akBaseObject, ObjectReference akReference)
    if repository.playerTrackingOnObjectEquipped
        string itemEquipped = akBaseObject.getname()
        string itemenchant = akBaseObject.GetEnchantment().getname()
        if itemenchant != "" ;filtering out enchantments to avoid spamming the LLM with confusing feedback
            ;Debug.MessageBox("The player equipped " + itemEquipped)
            if itemEquipped != "Mantella"
                SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", "The player equipped " + itemEquipped + ".\n", 2)
            endif
        endif
    endif
endEvent


Event OnItemUnequipped (Form akBaseObject, ObjectReference akReference)
    if repository.playerTrackingOnObjectUnequipped
        string itemUnequipped = akBaseObject.getname()
        ;Debug.MessageBox("The player unequipped " + itemUnequipped)
        if itemUnequipped != "Mantella Enchantment" && itemUnequipped != "Mantella"
            SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", "The player unequipped " + itemUnequipped + ".\n", 2)
        Endif
    endif
endEvent

Event OnSit(ObjectReference akFurniture)
    if repository.playerTrackingOnSit
        ;Debug.MessageBox("The player sat down.")
        String furnitureName = akFurniture.getbaseobject().getname()
        if furnitureName != "Power Armor"
            SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", "The player rested on / used a(n) "+furnitureName+".\n", 2)
        endif
    endif
endEvent


Event OnGetUp(ObjectReference akFurniture)
    if repository.playerTrackingOnGetUp
        ;Debug.MessageBox("The player stood up.")
        String furnitureName = akFurniture.getbaseobject().getname()
        if furnitureName != "Power Armor"
            SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", "The player stood up from a(n) "+furnitureName+".\n", 2)
        endif    
    endif
EndEvent


Event OnDying(Actor akKiller)
    SUP_F4SE.WriteStringToFile("_mantella_end_conversation.txt", "True",0)
EndEvent

string lastWeaponFired =""
Event OnPlayerFireWeapon(Form akBaseObject)
    if repository.playerTrackingFireWeapon 
        string weaponName=akBaseObject.getname()
        if weaponName!="Mantella"
            if lastWeaponFired!=akBaseObject && !repository.EventFireWeaponSpamBlocker
                SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", "The player fired their "+akBaseObject.getname()+" weapon.\n", 2)
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
            SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", "The player consumed irradiated sustenance.\n", 2)
        elseif repository.EventRadiationDamageSpamBlocker!=true
            SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", "The player took damage from radiation exposure.\n", 2)
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
        ;    sleepMessage=messagePrefix+daysPassed+" days and "+hoursPassed+" hours.\n"
        ;    SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", sleepMessage, 2)
        ;Else
            int hoursPassed=Math.Floor(timeSlept*24)
            sleepMessage=messagePrefix+hoursPassed+" hours.\n"
            SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", sleepMessage, 2)
        ;endif
    endif
EndEvent

Event OnCripple(ActorValue akActorValue, bool abCrippled)
    if repository.playerTrackingCripple
        string messageSuffix=" is crippled.\n"
        if !abCrippled
            messageSuffix=" is now healed.\n"
        endif
        if akActorValue
            SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt","The player's "+akActorValue.getname()+messageSuffix,2)
        endif
    endif

EndEvent
