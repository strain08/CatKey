#Requires AutoHotkey v2.0
#SingleInstance Force

; CatKey: locks the keyboard after a period of no input so a cat can't type.
; The screens dim with a message; double-click anywhere to unlock.
; While locked the power and sleep buttons do nothing. Ctrl+Alt+Del always works.
; Settings live in CatKey.ini, created with defaults on first run.

#Include %A_ScriptDir%\lib\Settings.ahk
#Include %A_ScriptDir%\lib\PowerButtons.ahk
#Include %A_ScriptDir%\lib\KeyBlock.ahk
#Include %A_ScriptDir%\lib\Overlay.ahk
#Include %A_ScriptDir%\lib\Controller.ahk
#Include %A_ScriptDir%\lib\Autostart.ahk

; Hooks make A_TimeIdlePhysical ignore simulated input
InstallKeybdHook()
InstallMouseHook()

cfg := Settings(A_ScriptDir "\CatKey.ini")
ctrl := CatKeyController(cfg.IdleTimeoutMin * 60000, Overlay(cfg.OverlayText), KeyBlock()
    , PowerButtons(A_ScriptDir "\CatKey.state"))
ctrl.RecoverFromCrash()
OnExit((*) => ctrl.Shutdown())

if FileExist(A_ScriptDir "\CatKey.ico")
    TraySetIcon(A_ScriptDir "\CatKey.ico")
A_IconTip := "CatKey"
A_TrayMenu.Delete()
A_TrayMenu.Add("Lock now", (*) => ctrl.Lock())
A_TrayMenu.Add("Pause CatKey", TogglePause)
A_TrayMenu.Add()
startup := Autostart()
A_TrayMenu.Add("Run at startup", ToggleAutostart)
if startup.IsEnabled()
    A_TrayMenu.Check("Run at startup")
A_TrayMenu.Add()
A_TrayMenu.Add("Exit", (*) => ExitApp())

; Release the keyboard when Windows locks (Win+L, sleep, timeout) so the PIN
; can be typed on the lock screen
WM_WTSSESSION_CHANGE := 0x2B1, WTS_SESSION_LOCK := 7, WTS_SESSION_UNLOCK := 8
DllCall("Wtsapi32\WTSRegisterSessionNotification", "Ptr", A_ScriptHwnd, "UInt", 0)
OnMessage(WM_WTSSESSION_CHANGE, OnSessionChange)
OnExit(UnregisterSessionNotification)

SetTimer(() => ctrl.Tick(A_TimeIdlePhysical), 1000)

OnSessionChange(wParam, *) {
    if wParam = WTS_SESSION_LOCK
        ctrl.OnSessionLock()
    else if wParam = WTS_SESSION_UNLOCK
        ctrl.OnSessionUnlock()
}

; Must not return a value: a non-zero return from an OnExit callback cancels the exit
UnregisterSessionNotification(*) {
    DllCall("Wtsapi32\WTSUnRegisterSessionNotification", "Ptr", A_ScriptHwnd)
}

TogglePause(itemName, *) {
    if ctrl.TogglePause()
        A_TrayMenu.Check(itemName)
    else
        A_TrayMenu.Uncheck(itemName)
}

ToggleAutostart(itemName, *) {
    try enabled := startup.Toggle()
    catch as e {
        MsgBox("Couldn't change the startup setting:`n" e.Message, "CatKey", "Icon!")
        return
    }
    if enabled
        A_TrayMenu.Check(itemName)
    else
        A_TrayMenu.Uncheck(itemName)
}
