Scriptname MantellaEffectScript extends activemagiceffect
Topic property MantellaDialogueLine auto

MantellaRepository property repository auto
string wavfilelocation="Data\\Sound\\Voice\\Mantella.esp\\MutantellaOutput1.wav"
float localMenuTimer

event OnEffectStart(Actor target, Actor caster)
        debug.notification("Cleaning up before starting conversation")
        repository.endFlagMantellaConversationOne = True
        Utility.Wait(0.5)
        repository.endFlagMantellaConversationOne = False

        String actorId = (target.getactorbase() as form).getformid()
        debug.notification("Actor ID is "+actorId)
        ;MiscUtil.WriteToFile("_mantella_current_actor_id.txt", actorId, append=false) THIS IS HOW THE FUNCTION LOOKS IN SKYRIM
        ;SUP_F4SE.WriteStringToFile(string sFilePath,string sText, int iAppend [0 for clean file, 1 for append, 2 for append with new line])
        SUP_F4SE.WriteStringToFile("_mantella_current_actor_id.txt",actorId, 0)
        string actorName = target.GetDisplayName()
        SUP_F4SE.WriteStringToFile("_mantella_current_actor.txt",actorName, 0)
        ;this will eventually be rewritten when multi-NPC conversation is implemented in FO4
        SUP_F4SE.WriteStringToFile("_mantella_active_actors.txt",actorName, 2)
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

        ;not currently implemented properly because Fallout time function needs a bit of modification either on papyrus or python side before
        int Time = 8  
        SUP_F4SE.WriteStringToFile("_mantella_in_game_time.txt", Time, 0)

        ;will eventually be modified when multi-NPC conversation are added to FO4
        int actorCount = 1
        SUP_F4SE.WriteStringToFile("_mantella_actor_count.txt", actorCount, 0)
        string sayFinalLine
        repository.endFlagMantellaConversationOne = false
        int loopCount
        if actorCount == 1 ; reset player input if this is the first actor selected
            SUP_F4SE.WriteStringToFile("_mantella_text_input_enabled.txt", "False", 0)
            SUP_F4SE.WriteStringToFile("_mantella_text_input.txt", "", 0)
        endif
        debug.notification("Initial setup finished")
        

        while repository.endFlagMantellaConversationOne == false
            MainConversationLoop( target, caster, loopCount)
            loopCount+=1
            if sayFinalLine == "True"
                repository.endFlagMantellaConversationOne = True
                localMenuTimer = -1
            endIf
            sayFinalLine = SUP_F4SE.ReadStringFromFile("_mantella_end_conversation.txt",0, 2) 
        endWhile
        debug.messagebox("Conversation with "+actorName+" has ended")

endevent

function MainConversationLoop(Actor target, Actor caster, int loopCount)
        String sayLine = SUP_F4SE.ReadStringFromFile("_mantella_say_line.txt",0,99) 

        if sayLine != "False" && !SUP_F4SE.IsMenuModeActive()
            target.SetLookAt(caster, false)
            Utility.wait (0.1)
            ;This function is there to activate the lip file, the audio for MantellaDialogue line is actually 10 seconds of silence.
            target.Say(MantellaDialogueLine, abSpeakInPlayersHead=false)
            sayline = setWavLocationAndGetReturnLine(sayline)
            debug.notification(target.GetDisplayName()+":"+sayline)
                       
            ;SUP_F4SE has to be use instead of target.say() because Fallout 4 will hold previous voiceline inside its cache unlike Skyrim
            SUP_F4SE.MP3LoadFile(wavfilelocation)
            SUP_F4SE.MP3Play() 
                ;while SUP_F4SE.MP3IsPlaying()
            while SUP_F4SE.MP3HasFinishedPlaying() != true
                Utility.wait (0.1)
            endWhile
            ;debug.messagebox(sayline+" has finished playing")
            Utility.wait (0.8)
            SUP_F4SE.MP3Stop()
            SUP_F4SE.WriteStringToFile("_mantella_say_line.txt", "False", 0)
            localMenuTimer = -1
        endif

        if loopCount % 5 == 0
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

endfunction

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