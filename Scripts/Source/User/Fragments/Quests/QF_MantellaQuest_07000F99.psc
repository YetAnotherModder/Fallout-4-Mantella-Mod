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
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment
