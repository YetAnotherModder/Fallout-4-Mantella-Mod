;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname Fragments:Quests:QF_MantellaQuest_07000F99 Extends Quest Hidden Const

;BEGIN FRAGMENT Fragment_Stage_0201_Item_00
Function Fragment_Stage_0201_Item_00()
;BEGIN AUTOCAST TYPE MantellaRepository
Quest __temp = self as Quest
MantellaRepository kmyQuest = __temp as MantellaRepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.RegisterForMenuOpenCloseEvent("PipboyMenu")
kmyQuest.QuestSelector=1
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0301_Item_00
Function Fragment_Stage_0301_Item_00()
;BEGIN AUTOCAST TYPE MantellaRepository
Quest __temp = self as Quest
MantellaRepository kmyQuest = __temp as MantellaRepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.reinitializeVariables()
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0302_Item_00
Function Fragment_Stage_0302_Item_00()
;BEGIN AUTOCAST TYPE MantellaRepository
Quest __temp = self as Quest
MantellaRepository kmyQuest = __temp as MantellaRepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.RegisterForMenuOpenCloseEvent("PipboyMenu")
kmyQuest.QuestSelector=2
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0303_Item_00
Function Fragment_Stage_0303_Item_00()
;BEGIN AUTOCAST TYPE MantellaRepository
Quest __temp = self as Quest
MantellaRepository kmyQuest = __temp as MantellaRepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.toggleNotificationSubtitles(false)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0304_Item_00
Function Fragment_Stage_0304_Item_00()
;BEGIN AUTOCAST TYPE MantellaRepository
Quest __temp = self as Quest
MantellaRepository kmyQuest = __temp as MantellaRepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.toggleNotificationSubtitles(true)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0401_Item_00
Function Fragment_Stage_0401_Item_00()
;BEGIN AUTOCAST TYPE MantellaRepository
Quest __temp = self as Quest
MantellaRepository kmyQuest = __temp as MantellaRepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.togglePlayerEventTracking(false)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0402_Item_00
Function Fragment_Stage_0402_Item_00()
;BEGIN AUTOCAST TYPE MantellaRepository
Quest __temp = self as Quest
MantellaRepository kmyQuest = __temp as MantellaRepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.togglePlayerEventTracking(true)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0403_Item_00
Function Fragment_Stage_0403_Item_00()
;BEGIN AUTOCAST TYPE MantellaRepository
Quest __temp = self as Quest
MantellaRepository kmyQuest = __temp as MantellaRepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.toggleTargetEventTracking(false)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0404_Item_00
Function Fragment_Stage_0404_Item_00()
;BEGIN AUTOCAST TYPE MantellaRepository
Quest __temp = self as Quest
MantellaRepository kmyQuest = __temp as MantellaRepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.toggleTargetEventTracking(true)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment
