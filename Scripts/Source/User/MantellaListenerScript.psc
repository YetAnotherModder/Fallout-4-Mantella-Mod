Scriptname MantellaListenerScript extends ReferenceAlias

Spell property MantellaSpell auto
Actor property PlayerRef auto
Weapon property MantellaGun auto
Holotape property MantellaSettingsHolotape auto
Quest Property MantellaActorList  Auto  
ReferenceAlias Property PotentialActor1  Auto  
ReferenceAlias Property PotentialActor2  Auto  
MantellaRepository property repository auto
GlobalVariable property MantellaRadiantEnabled auto
GlobalVariable property MantellaRadiantDistance auto
GlobalVariable property MantellaRadiantFrequency auto
int RadiantFrequencyTimerID=1
Float meterUnits = 78.74

Event OnInit ()
   PlayerRef.AddItem(MantellaGun, 1, false)
   PlayerRef.AddItem(MantellaSettingsHolotape, 1, false)
   Utility.Wait(0.5)
   ;debug.messagebox("OnInit : Starting timer "+RadiantFrequencyTimerID+" for "+repository.radiantFrequency)
   StartTimer(MantellaRadiantFrequency.getValue(),RadiantFrequencyTimerID)   
endEvent


Float Function ConvertMeterToGameUnits(Float meter)
    Return Meter * meterUnits
EndFunction

Float Function ConvertGameUnitsToMeter(Float gameUnits)
    Return gameUnits / meterUnits
EndFunction

Event OnPlayerLoadGame()
debug.messagebox("Game loaded")
   ;debug.messagebox("OnPLayerLoadGame : Starting timer "+RadiantFrequencyTimerID+" for "+repository.radiantFrequency)
   StartTimer(MantellaRadiantFrequency.getValue(),RadiantFrequencyTimerID)   
EndEvent

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