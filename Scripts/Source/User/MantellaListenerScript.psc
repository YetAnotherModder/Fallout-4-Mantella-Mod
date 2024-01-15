Scriptname MantellaListenerScript extends ReferenceAlias

Actor property PlayerRef auto
Weapon property MantellaGun auto

Event OnInit ()
   
   PlayerRef.AddItem(MantellaGun, 1, false)
    
endEvent