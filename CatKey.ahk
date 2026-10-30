#Requires AutoHotkey v2.0
#SingleInstance Force

; CatKey: locks the keyboard after a period of no input so a cat can't type.
; The screens dim with "CatKey locked"; double-click anywhere to unlock.
; While locked the power and sleep buttons do nothing. Ctrl+Alt+Del always works.

IdleTimeoutMin := 5

#Include %A_ScriptDir%\lib\PowerButtons.ahk
#Include %A_ScriptDir%\lib\KeyBlock.ahk
#Include %A_ScriptDir%\lib\Overlay.ahk
#Include %A_ScriptDir%\lib\Controller.ahk

; Hooks make A_TimeIdlePhysical ignore simulated input
InstallKeybdHook()
InstallMouseHook()

ctrl := CatKeyController(IdleTimeoutMin * 60000, Overlay(), KeyBlock()
    , PowerButtons(A_ScriptDir "\CatKey.state"))
ctrl.RecoverFromCrash()
OnExit((*) => ctrl.Shutdown())

A_IconTip := "CatKey"
A_TrayMenu.Delete()
A_TrayMenu.Add("Lock now", (*) => ctrl.Lock())
A_TrayMenu.Add("Pause CatKey", TogglePause)
A_TrayMenu.Add()
A_TrayMenu.Add("Exit", (*) => ExitApp())

SetTimer(() => ctrl.Tick(A_TimeIdlePhysical), 1000)

TogglePause(itemName, *) {
    if ctrl.TogglePause()
        A_TrayMenu.Check(itemName)
    else
        A_TrayMenu.Uncheck(itemName)
}
