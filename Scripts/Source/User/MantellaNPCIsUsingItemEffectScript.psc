Scriptname MantellaNPCIsUsingItemEffectScript extends activemagiceffect

sound property StimpakSound auto
sound property RadawaySound auto
spell property MantellaStimpakSpell auto
spell property MantellaRadawaySpell auto
MantellaRepository property repository auto
Actor property playerRef auto
Idle Property HealingIdle auto
Faction Property MantellaFunctionSourceFaction Auto
Faction Property MantellaFunctionModeFaction Auto
Potion Property StimpakItem auto
Potion Property RadawayItem auto

event OnEffectStart(Actor target, Actor caster)
    ;if repository.NPCAIItemToUseSelector==1
    int ItemMode = caster.GetFactionRank(MantellaFunctionModeFaction)
    if ItemMode == 1 ;1 equal stimpak
        if caster.GetItemCount(StimpakItem)>0
            debug.notification(caster.GetDisplayName()+" is using a stimpak on "+target.GetDisplayName())
            ;self.GetCasterActor().PlayIdle(HealingIdle) ;doesn't seem to be working
            MantellaStimpakSpell.Cast(target, target)
            StimpakSound.play(target)
            caster.RemoveItem(StimpakItem, 1, abSilent = true, akOtherContainer = None)
            caster.SetFactionRank(MantellaFunctionSourceFaction, 0) ;Resetting the AI to waiting around
            caster.EvaluatePackage()
        else
            debug.notification(caster.GetDisplayName()+" has no stimpaks.")
            caster.SetFactionRank(MantellaFunctionSourceFaction, 0)  ;Resetting the AI to waiting around
            caster.EvaluatePackage()
        endif
    ElseIf ItemMode == 2
        if caster.GetItemCount(RadawayItem)>0
            debug.notification(caster.GetDisplayName()+" is using a RadAway on "+target.GetDisplayName())
            ;self.GetCasterActor().PlayIdle(HealingIdle) ;doesn't seem to be working
            MantellaRadawaySpell.Cast(target, target)
            RadawaySound.play(target)
            caster.RemoveItem(RadawayItem, 1, abSilent = true, akOtherContainer = None)
            caster.SetFactionRank(MantellaFunctionSourceFaction, 0) ;Resetting the AI to waiting around
            caster.EvaluatePackage()
        else
            debug.notification(caster.GetDisplayName()+" doesn't have any RadAway.")
            caster.SetFactionRank(MantellaFunctionSourceFaction, 0)  ;Resetting the AI to waiting around
            caster.EvaluatePackage()
        endif
    endif
EndEvent