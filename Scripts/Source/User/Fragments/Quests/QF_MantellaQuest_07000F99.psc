;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname Fragments:Quests:QF_MantellaQuest_07000F99 Extends Quest Hidden Const

;BEGIN FRAGMENT Fragment_Stage_0201_Item_00
Function Fragment_Stage_0201_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.RegisterForMenuOpenCloseEvent("PipboyMenu")

kmyQuest.MenuEventSelector=1

Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0202_Item_00
Function Fragment_Stage_0202_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.RegisterForMenuOpenCloseEvent("PipboyMenu")

kmyQuest.MenuEventSelector=3


Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0203_Item_00
Function Fragment_Stage_0203_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.RegisterForMenuOpenCloseEvent("PipboyMenu")
kmyQuest.MenuEventSelector=5
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0204_Item_00
Function Fragment_Stage_0204_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.RegisterForMenuOpenCloseEvent("PipboyMenu")
kmyQuest.MenuEventSelector=4
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0205_Item_00
Function Fragment_Stage_0205_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.RegisterForMenuOpenCloseEvent("PipboyMenu")
kmyQuest.MenuEventSelector=6
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0206_Item_00
Function Fragment_Stage_0206_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.RegisterForMenuOpenCloseEvent("PipboyMenu")
kmyQuest.MenuEventSelector=7
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0207_Item_00
Function Fragment_Stage_0207_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.RegisterForMenuOpenCloseEvent("PipboyMenu")
kmyQuest.MenuEventSelector=8
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0208_Item_00
Function Fragment_Stage_0208_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.TriggerTutorialVariables(false)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0301_Item_00
Function Fragment_Stage_0301_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.reinitializeVariables()

Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0302_Item_00
Function Fragment_Stage_0302_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.RegisterForMenuOpenCloseEvent("PipboyMenu")

kmyQuest.MenuEventSelector=2

Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0303_Item_00
Function Fragment_Stage_0303_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.RestartMantellaExe()
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0305_Item_00
Function Fragment_Stage_0305_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.togglemicrophoneEnabled(false)

Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0306_Item_00
Function Fragment_Stage_0306_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.togglemicrophoneEnabled(true)

Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0307_Item_00
Function Fragment_Stage_0307_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.ToggleActivatePerk()
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0401_Item_00
Function Fragment_Stage_0401_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.togglePlayerEventTracking(false)

Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0402_Item_00
Function Fragment_Stage_0402_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.togglePlayerEventTracking(true)

Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0403_Item_00
Function Fragment_Stage_0403_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.toggleTargetEventTracking(false)

Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0404_Item_00
Function Fragment_Stage_0404_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.toggleTargetEventTracking(true)

Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0405_Item_00
Function Fragment_Stage_0405_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.UnRegisterForOnCrosshairRefChange()
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0406_Item_00
Function Fragment_Stage_0406_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.RegisterForOnCrosshairRefChange()
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0407_Item_00
Function Fragment_Stage_0407_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.toggleAllowVision(false)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0408_Item_00
Function Fragment_Stage_0408_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.toggleAllowVision(true)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0409_Item_00
Function Fragment_Stage_0409_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.toggleAllowVisionHints(true)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0410_Item_00
Function Fragment_Stage_0410_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.toggleAllowVisionHints(false)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0411_Item_00
Function Fragment_Stage_0411_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyquest.togglePlayerItemEventTracking(false)
reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0412_Item_00
Function Fragment_Stage_0412_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyquest.togglePlayerItemEventTracking(true)
reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0413_Item_00
Function Fragment_Stage_0413_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyquest.togglePlayerHitEventTracking(false)
reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0414_Item_00
Function Fragment_Stage_0414_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyquest.togglePlayerHitEventTracking(true)
reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0415_Item_00
Function Fragment_Stage_0415_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyquest.togglePlayerLocationChangeEventTracking(false)
reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0416_Item_00
Function Fragment_Stage_0416_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyquest.togglePlayerLocationChangeEventTracking(true)
reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0417_Item_00
Function Fragment_Stage_0417_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyquest.togglePlayerEquipEventTracking(false)
reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0418_Item_00
Function Fragment_Stage_0418_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyquest.togglePlayerEquipEventTracking(true)
reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0419_Item_00
Function Fragment_Stage_0419_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyquest.togglePlayerSitEventTracking(false)
reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0420_Item_00
Function Fragment_Stage_0420_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyquest.togglePlayerSitEventTracking(true)
reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0421_Item_00
Function Fragment_Stage_0421_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyquest.togglePlayerWeaponFireEventTracking(false)
reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0422_Item_00
Function Fragment_Stage_0422_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyquest.togglePlayerWeaponFireEventTracking(true)
reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0423_Item_00
Function Fragment_Stage_0423_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyquest.togglePlayerRadiationDmgEventTracking(false)
reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0424_Item_00
Function Fragment_Stage_0424_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyquest.togglePlayerRadiationDmgEventTracking(true)
reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0425_Item_00
Function Fragment_Stage_0425_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyquest.togglePlayerSleepEventTracking(false)
reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0426_Item_00
Function Fragment_Stage_0426_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyquest.togglePlayerSleepEventTracking(true)
reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0427_Item_00
Function Fragment_Stage_0427_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyquest.togglePlayerCrippleEventTracking(false)
reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0428_Item_00
Function Fragment_Stage_0428_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyquest.togglePlayerCrippleEventTracking(true)
reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0429_Item_00
Function Fragment_Stage_0429_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyquest.togglePlayerHealTeammateEventTracking(false)
reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0430_Item_00
Function Fragment_Stage_0430_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyquest.togglePlayerHealTeammateEventTracking(true)
reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0501_Item_00
Function Fragment_Stage_0501_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.toggleAllowAggro(false)

Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0502_Item_00
Function Fragment_Stage_0502_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.toggleAllowAggro(true)

Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0503_Item_00
Function Fragment_Stage_0503_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.toggleAllowFollow(false)

Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0504_Item_00
Function Fragment_Stage_0504_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.toggleAllowFollow(true)
kmyQuest.toggleAllowNPCsStayInPlace(true)

Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0505_Item_00
Function Fragment_Stage_0505_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.toggleAllowNPCsStayInPlace(false)

Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0506_Item_00
Function Fragment_Stage_0506_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.toggleAllowNPCsStayInPlace(true)

Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0507_Item_00
Function Fragment_Stage_0507_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.toggleActionInventory(false)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0508_Item_00
Function Fragment_Stage_0508_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.toggleActionInventory(true)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0509_Item_00
Function Fragment_Stage_0509_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.toggleAllowFunctionCalling(false)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0510_Item_00
Function Fragment_Stage_0510_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.toggleAllowFunctionCalling(true)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0601_Item_00
Function Fragment_Stage_0601_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.listMenuState("NPC_Actions")

Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0602_Item_00
Function Fragment_Stage_0602_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.listMenuState("Main_Settings")

Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0603_Item_00
Function Fragment_Stage_0603_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.listMenuState("HTTP_Settings")

Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0604_Item_00
Function Fragment_Stage_0604_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.listMenuState("Events")

Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0605_Item_00
Function Fragment_Stage_0605_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.listMenuState("Hotkeys")

Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0606_Item_00
Function Fragment_Stage_0606_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.listMenuState("Vision")

Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0607_Item_00
Function Fragment_Stage_0607_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.listMenuState("Radiant")

Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0608_Item_00
Function Fragment_Stage_0608_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.listMenuState("Conversation_timeout")

Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0701_Item_00
Function Fragment_Stage_0701_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.SetVisionResolution("auto")
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0702_Item_00
Function Fragment_Stage_0702_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.SetVisionResolution("high")
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0703_Item_00
Function Fragment_Stage_0703_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.SetVisionResolution("low")
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0704_Item_00
Function Fragment_Stage_0704_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.SetVisionResize(512)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0705_Item_00
Function Fragment_Stage_0705_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.SetVisionResize(1024)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0706_Item_00
Function Fragment_Stage_0706_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.SetVisionResize(1536)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0707_Item_00
Function Fragment_Stage_0707_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.SetVisionResize(2048)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0708_Item_00
Function Fragment_Stage_0708_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.SetVisionResize(2560)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0801_Item_00
Function Fragment_Stage_0801_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.SetHTTPTimeoutInMinutes(2)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0802_Item_00
Function Fragment_Stage_0802_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.SetHTTPTimeoutInMinutes(4)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0803_Item_00
Function Fragment_Stage_0803_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.SetHTTPTimeoutInMinutes(20)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0804_Item_00
Function Fragment_Stage_0804_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.SetHTTPTimeoutInMinutes(60)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0805_Item_00
Function Fragment_Stage_0805_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.SetHTTPTimeoutInMinutes(1440)
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0901_Item_00
Function Fragment_Stage_0901_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.TIM_Set_HTTP_Port("29999")
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0902_Item_00
Function Fragment_Stage_0902_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.TIM_Set_HTTP_Port("39999")
Reset()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0903_Item_00
Function Fragment_Stage_0903_Item_00()
;BEGIN AUTOCAST TYPE mantellarepository
Quest __temp = self as Quest
mantellarepository kmyQuest = __temp as mantellarepository
;END AUTOCAST
;BEGIN CODE
kmyQuest.TIM_Set_HTTP_Port("49999")
Reset()
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment
