;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname Fragments:Perks:PRKF_MantellaActivatePerk_07084DED Extends Perk Hidden Const

;BEGIN FRAGMENT Fragment_Entry_00
Function Fragment_Entry_00(ObjectReference akTargetRef, Actor akActor)
;BEGIN CODE
MantellaSpell.cast(Game.GetPlayer(), akTargetRef)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

SPELL Property MantellaSpell Auto Const Mandatory
