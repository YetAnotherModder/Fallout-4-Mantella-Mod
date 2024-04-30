;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname Fragments:Perks:PRKF_MantellaActivatePerk_070780FC Extends Perk Hidden Const

;BEGIN FRAGMENT Fragment_Entry_01
Function Fragment_Entry_01(ObjectReference akTargetRef, Actor akActor)
;BEGIN CODE
MantellaSpell.cast(Game.GetPlayer(), akTargetRef)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

SPELL Property MantellaSpell Auto Const Mandatory
