Scriptname MantellaEffectScript extends activemagiceffect
Import SUP_F4SE
Topic property MantellaDialogueLine auto
GlobalVariable property MantellaWaitTimeBuffer auto

MantellaRepository property repository auto
string wavfilelocation="Data\\Sound\\Voice\\Mantella.esp\\MutantellaOutput1.wav"
float localMenuTimer
Float meterUnits = 78.74

event OnEffectStart(Actor target, Actor caster)
    ;cleanupstep below checks if the player is targeting someone and cleans up all conversation if that's the case
    bool casterIsPlayer=false
    if caster == Game.GetPlayer()
        casterIsPlayer=true
        debug.notification("Cleaning up before starting conversation")
        repository.endFlagMantellaConversationOne = True
        Utility.Wait(0.5)
        repository.endFlagMantellaConversationOne = False
    endif
    String activeActors = SUP_F4SE.ReadStringFromFile("_mantella_active_actors.txt",0,10)
    String actorCountString = SUP_F4SE.ReadStringFromFile("_mantella_actor_count.txt",0,1) 
    int actorCount = actorCountString as int
    String character_selection_enabled = SUP_F4SE.ReadStringFromFile("_mantella_character_selection.txt",0,1) 

    string actorName = target.GetDisplayName()
    String casterName = caster.getdisplayname()
    ;debug.messagebox ("MantellaEffectScript:"+casterName+" casting Mantella on "+actorName)
    ;if radiant dialogue between two NPCs, label them 1 & 2
    if (casterName == actorName)
        if actorCount == 0
            actorName = actorName + " 1"
            casterName = casterName + " 2"
        elseIf actorCount == 1
            actorName = actorName + " 2"
            casterName = casterName + " 1"
        endIf
    endIf

    int index = SUP_F4SE.SUPStringFind(activeActors, actorName,0,0)
    bool actorAlreadyLoaded = true
    if index == -1
        actorAlreadyLoaded = false
    endIf

    if (actorAlreadyLoaded == false) && (character_selection_enabled == "True")
        ;ENABLE THE NEXT LINE AFTER SETTING UP CK
        ;TargetRefAlias.ForceRefTo(target)
    
        String actorId = (target.getactorbase() as form).getformid()
        ;debug.notification("Actor ID is "+actorId)
        ;MiscUtil.WriteToFile("_mantella_current_actor_id.txt", actorId, append=false) THIS IS HOW THE FUNCTION LOOKS IN SKYRIM
        ;SUP_F4SE.WriteStringToFile(string sFilePath,string sText, int iAppend [0 for clean file, 1 for append, 2 for append with new line])
        SUP_F4SE.WriteStringToFile("_mantella_current_actor_id.txt",actorId, 0)
        SUP_F4SE.WriteStringToFile("_mantella_current_actor.txt",actorName, 0)
        ;this will eventually be rewritten when multi-NPC conversation is implemented in FO4
        SUP_F4SE.WriteStringToFile("_mantella_active_actors.txt",actorName, 1)
        ;debug.messagebox("Current active actors "+SUP_F4SE.ReadStringFromFile("_mantella_active_actors.txt",0,10))
        SUP_F4SE.WriteStringToFile("_mantella_character_selection.txt","false",0)

        String actorSex = target.getleveledactorbase().getsex()
        SUP_F4SE.WriteStringToFile("_mantella_actor_sex.txt", actorSex, 0)

        String actorRace = target.getrace()
        SUP_F4SE.WriteStringToFile("_mantella_actor_race.txt", actorRace, 0)

        String actorRelationship = target.getrelationshiprank(game.getplayer())
        SUP_F4SE.WriteStringToFile("_mantella_actor_relationship.txt", actorRelationship, 0)

        String actorVoiceType = target.GetVoiceType()
        SUP_F4SE.WriteStringToFile("_mantella_actor_voice.txt", actorVoiceType, 0)
        ;the below is to build a substring to use later to find the correct wav file 
        String isEnemy = "False"
        if (target.getcombattarget() == game.getplayer())
            isEnemy = "True"
        endIf
        SUP_F4SE.WriteStringToFile("_mantella_actor_is_enemy.txt", isEnemy, 0)

        String currLoc = (caster.GetCurrentLocation() as form).getname()
        if currLoc == ""
            currLoc = "Boston area"
        endIf
        SUP_F4SE.WriteStringToFile("_mantella_current_location.txt", currLoc, 0)

        int Time = GetCurrentHourOfDay()
        SUP_F4SE.WriteStringToFile("_mantella_in_game_time.txt", Time, 0)

        ;will eventually be modified when multi-NPC conversation are added to FO4
        actorCount += 1
        SUP_F4SE.WriteStringToFile("_mantella_actor_count.txt", actorCount, 0)

        if actorCount == 1 ; reset player input if this is the first actor selected
            SUP_F4SE.WriteStringToFile("_mantella_text_input_enabled.txt", "False", 0)
            SUP_F4SE.WriteStringToFile("_mantella_text_input.txt", "", 0)
            ;NEED TO ENABLE ONCE EVENT TRACKING FOR PLAYER IS ADDED
            ;SUP_F4SE.WriteStringToFile("_mantella_in_game_events.txt", "", 0)
        endif
        ;debug.notification("Initial setup finished")
        
        if casterIsPlayer
		    Debug.Notification("Starting conversation with " + actorName)
        elseIf actorCount == 1
            Debug.Notification("Starting radiant dialogue with " + actorName + " and " + casterName)
        endIf

        
        repository.endFlagMantellaConversationOne = false
        bool endConversation = false
        string sayFinalLine
        String sayLineFile = "_mantella_say_line_"+actorCount+".txt"
        int loopCount

        ; Wait for first voiceline to play to avoid old conversation playing
        Utility.Wait(0.5)

        SUP_F4SE.WriteStringToFile("_mantella_character_selected.txt", "True", 0)
        while repository.endFlagMantellaConversationOne == false && endConversation == false
            if actorCount == 1
                MainConversationLoop( target, caster, loopCount)
                loopCount+=1
            Else
                ConversationLoop(target, caster, actorName, sayLineFile)
            endif


            if sayFinalLine == "True"
                endConversation = True
                localMenuTimer = -1
            endIf
            sayFinalLine = SUP_F4SE.ReadStringFromFile("_mantella_end_conversation.txt",0, 2) 
        endWhile
        debug.notification("Conversation with "+actorName+" has ended")
    Else
        Debug.Notification("NPC not added. Please try again after your next response.")    
    endif
    

endevent

function MainConversationLoop(Actor target, Actor caster, int loopCount)
        String sayLine = SUP_F4SE.ReadStringFromFile("_mantella_say_line.txt",0,99) 

        if sayLine != "False" && !SUP_F4SE.IsMenuModeActive()
            target.SetLookAt(caster, false)
            Utility.wait (0.1)
            ;This function is there to activate the lip file, the audio for MantellaDialogue line is actually 10 seconds of silence.
            target.Say(MantellaDialogueLine, abSpeakInPlayersHead=false)
            ;###the function  internalMantellaAudioPlay is deprecated with F4SE 11.60   ###
            ;internalMantellaAudioPlay(sayline, target) 
            externalMantellaAudioPlay(sayline, target)
            SUP_F4SE.WriteStringToFile("_mantella_say_line.txt", "False", 0)
            localMenuTimer = -1
           
        endif
            

        if loopCount % 5 == 0
            ;move Time tracking to this section for it to run less frequently
            int Time = GetCurrentHourOfDay()
            SUP_F4SE.WriteStringToFile("_mantella_in_game_time.txt", Time, 0)

            String status = SUP_F4SE.ReadStringFromFile("_mantella_status.txt",0,99) 
            if status != "False"
                Debug.Notification(status)
                SUP_F4SE.WriteStringToFile("_mantella_status.txt", "False", 0)
            endIf
            
            ;text input to implement later
            String playerResponse = SUP_F4SE.ReadStringFromFile ("_mantella_text_input_enabled.txt",0,2) 
            if playerResponse == "True"
                StartTextTimer()
            endIf
        endIf

        if loopCount % 20 == 0
            String radiantDialogue = SUP_F4SE.ReadStringFromFile("_mantella_radiant_dialogue.txt",0,2) 
            if radiantDialogue == "True"
                float distanceBetweenActors = caster.GetDistance(target)
                float distanceToPlayer = ConvertGameUnitsToMeter(caster.GetDistance(game.getplayer()))
                ;Debug.Notification(distanceBetweenActors)
                ;TODO: allow distanceBetweenActos limit to be customisable
                if (distanceBetweenActors > 1500) || (distanceToPlayer > repository.radiantDistance) || (caster.GetCurrentLocation() != target.GetCurrentLocation()) || (caster.GetCurrentScene() != None) || (target.GetCurrentScene() != None)
                    Debug.messagebox("Conversation ended, possibly because of distance "+distanceBetweenActors)
                    SUP_F4SE.WriteStringToFile("_mantella_end_conversation.txt", "True", 0)
                endIf
            endIf
        endIf
endfunction

;### Function below is depcrecated with the updated of F4SE to 11.60 ###
; function internalMantellaAudioPlay(string sayline, actor target)
;    sayline = setWavLocationAndGetReturnLine(sayline)
;    debug.notification(target.GetDisplayName()+":"+sayline)
               
    ;SUP_F4SE has to be use instead of target.say() because Fallout 4 will hold previous voiceline inside its cache unlike Skyrim
;    SUP_F4SE.MP3LoadFile(wavfilelocation)
;    SUP_F4SE.MP3Play() 
        ;while SUP_F4SE.MP3IsPlaying()
;    while SUP_F4SE.MP3HasFinishedPlaying() != true
;        Utility.wait (0.1)
;    endWhile
    ;debug.messagebox(sayline+" has finished playing")
;    Utility.wait (MantellaWaitTimeBuffer.GetValue())
;    SUP_F4SE.MP3Stop()
;endfunction */


function externalMantellaAudioPlay(string sayline, actor target)
    sayline = setWavLocationAndGetReturnLine(sayline)
    SUP_F4SE.WriteStringToFile("_mantella_audio_ready.txt", "true", 0)
    debug.notification(target.GetDisplayName()+":"+sayline)
    string audioIsPlaying = "true"
    debug.trace("Starting while loop waiting for audio to finish playing")
    While audioIsPlaying == "true" && repository.endFlagMantellaConversationOne == false
        audioIsPlaying= SUP_F4SE.ReadStringFromFile("_mantella_audio_ready.txt",0,99)
    endwhile
endfunction

function ConversationLoop(Actor target, Actor caster, String actorName, String sayLineFile)
    String sayLine = SUP_F4SE.ReadStringFromFile(sayLineFile,0,99)
    if sayLine != "False"
        target.SetLookAt(caster, false)
        Utility.wait (0.1)
        ;This function is there to activate the lip file, the audio for MantellaDialogue line is actually 10 seconds of silence.
        target.Say(MantellaDialogueLine, abSpeakInPlayersHead=false)
        ;###the function  internalMantellaAudioPlay is deprecated with F4SE 11.60   ###
        ;internalMantellaAudioPlay(sayline, target) 
        externalMantellaAudioPlay(sayline, target)
        ; Set sayLine back to False once the voiceline has been triggered
        SUP_F4SE.WriteStringToFile(sayLineFile, "False", 0)
        localMenuTimer = -1
    endIf
endFunction

function StartTextTimer()
	localMenuTimer=180
    int localMenuTimerInt = Math.Floor(localMenuTimer)
	Debug.Notification("Awaiting player input for "+localMenuTimerInt+" seconds")
	String Monitorplayerresponse
	String timerCheckEndConversation
	;Debug.Notification("Timer is "+localMenuTimer)
	While localMenuTimer >= 0 && repository.endFlagMantellaConversationOne==false
		;Debug.Notification("Timer is "+localMenuTimer)
		Monitorplayerresponse = SUP_F4SE.ReadStringFromFile("_mantella_text_input_enabled.txt",0,2) 
		timerCheckEndConversation = SUP_F4SE.ReadStringFromFile("_mantella_end_conversation.txt",0,2) 
		;the next if clause checks if another conversation is already running and ends it.
		if timerCheckEndConversation == "true" ;|| repository.endFlagMantellaConversationOne==true (MAYBE ADD THIS BACK?)
			localMenuTimer = -1
            SUP_F4SE.WriteStringToFile("_mantella_say_line.txt", "False", 0)
			return
		endif
		if Monitorplayerresponse == "False"
			localMenuTimer = -1
		endif
		If localMenuTimer > 0
			Utility.Wait(1)
			if !SUP_F4SE.IsMenuModeActive()
				localMenuTimer = localMenuTimer - 1
			endif
			;Debug.Notification("Timer is "+localMenuTimer)
		elseif localMenuTimer == 0
			Monitorplayerresponse = "False"
			;added this as a safety check in case the player stays in a menu a long time.
            Monitorplayerresponse = SUP_F4SE.ReadStringFromFile("_mantella_text_input_enabled.txt",0,2)
			if Monitorplayerresponse == "True"
				;Debug.Notification("opening menu now")
				repository.OpenTextMenu()
                if repository.textinput != ""
                    SUP_F4SE.WriteStringToFile("_mantella_text_input_enabled.txt", "False", 0)
                    SUP_F4SE.WriteStringToFile("_mantella_text_input.txt", repository.textinput, 0)
                endIf
			endIf
			localMenuTimer = -1
		endIf
	endWhile
endFunction

string function setWavLocationAndGetReturnLine(string currentLine)
    ;This function tells FO4 from which wav file to read. It also reads the end of the line to be said and chops the end of the said line if it contains a Mutantella1 or Mutantella2 flag.
    int Mutantella1_Pos = SUP_F4SE.SUPStringFind(currentLine, "Mutantella1",0,0)
    if Mutantella1_Pos>=0
        currentLine = SUP_F4SE.stringFindSubString(currentLine,0,Mutantella1_Pos-1)
        wavfilelocation="Data\\Sound\\Voice\\Mantella.esp\\MutantellaOutput1.wav"
    ElseIf Mutantella1_Pos==-1
        int Mutantella2_Pos = SUP_F4SE.SUPStringFind(currentLine, "Mutantella2",0,0)
        if Mutantella2_Pos>=0
            currentLine = SUP_F4SE.stringFindSubString(currentLine,0,Mutantella2_Pos-1)
            wavfilelocation="Data\\Sound\\Voice\\Mantella.esp\\MutantellaOutput2.wav"
        endif
    else
        wavfilelocation="Data\\Sound\\Voice\\Mantella.esp\\MutantellaOutput1.wav"
    endif
    return currentLine
endfunction

int function GetCurrentHourOfDay()
	float Time = Utility.GetCurrentGameTime()
	Time -= Math.Floor(Time) ; Remove "previous in-game days passed" bit
	Time *= 24 ; Convert from fraction of a day to number of hours
	int Hour = Math.Floor(Time) ; Get whole hour
	return Hour
endFunction


Float Function ConvertMeterToGameUnits(Float meter)
    Return Meter * meterUnits
EndFunction

Float Function ConvertGameUnitsToMeter(Float gameUnits)
    Return gameUnits / meterUnits
EndFunction