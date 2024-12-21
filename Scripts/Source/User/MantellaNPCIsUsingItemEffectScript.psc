Scriptname MantellaNPCIsUsingItemEffectScript extends activemagiceffect

sound property StimpakSound auto
spell property MantellaStimpakSpell auto
MantellaRepository property repository auto
Actor property playerRef auto
Idle Property HealingIdle auto

event OnEffectStart(Actor target, Actor caster)
    if repository.NPCAIItemToUseSelector==1
        debug.notification(caster.GetDisplayName()+" is using a stimpack on "+playerRef.GetDisplayName())
        ;self.GetCasterActor().PlayIdle(HealingIdle) ;doesn't seem to be working
        MantellaStimpakSpell.Cast(playerRef, playerRef)
        StimpakSound.play(playerRef)
        repository.NPCAIItemToUseSelector=0
    endif
EndEvent