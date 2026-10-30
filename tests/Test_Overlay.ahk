#Requires AutoHotkey v2.0
#Include %A_ScriptDir%\Assert.ahk
#Include %A_ScriptDir%\..\lib\Overlay.ahk

WM_LBUTTONDOWN := 0x201
WM_LBUTTONDBLCLK := 0x203

global unlockCount := 0
CountUnlock() {
    global unlockCount
    unlockCount += 1
}

ov := Overlay()
ov.OnUnlock := CountUnlock
AssertEq(ov.IsShown, false, "hidden initially")

ov.Show()
ov.Show()
AssertEq(ov.IsShown, true, "shown after Show")
AssertEq(ov.Hwnds.Length, MonitorGetCount(), "one window per monitor (Show twice)")

for i, hwnd in ov.Hwnds {
    MonitorGet(i, &left, &top, &right, &bottom)
    WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
    AssertEq(x "," y "," w "," h, left "," top "," (right - left) "," (bottom - top), "window " i " covers monitor " i)
    AssertTrue(WinGetExStyle("ahk_id " hwnd) & 0x8, "window " i " is topmost")
    AssertEq(WinGetTransparent("ahk_id " hwnd), 77, "window " i " is dimmed to 77")
    AssertEq(ControlGetText("Static1", "ahk_id " hwnd), "CatKey locked", "window " i " shows text")
}

; A single click does nothing
PostMessage(WM_LBUTTONDOWN, 1, 0, , "ahk_id " ov.Hwnds[1])
Sleep(100)
AssertEq(unlockCount, 0, "single click ignored")

; Double-click on a window that isn't the overlay does nothing
other := Gui()
other.Show("w100 h100 NA")
PostMessage(WM_LBUTTONDBLCLK, 1, 0, , "ahk_id " other.Hwnd)
Sleep(100)
AssertEq(unlockCount, 0, "foreign window ignored")
other.Destroy()

; Double-click on the last monitor's window fires OnUnlock once
PostMessage(WM_LBUTTONDBLCLK, 1, 0, , "ahk_id " ov.Hwnds[ov.Hwnds.Length])
Sleep(100)
AssertEq(unlockCount, 1, "double-click fires OnUnlock")

ov.KeepOnTop()
AssertTrue(WinGetExStyle("ahk_id " ov.Hwnds[1]) & 0x8, "KeepOnTop keeps topmost")

hwnd1 := ov.Hwnds[1]
ov.Hide()
ov.Hide()
AssertEq(ov.IsShown, false, "hidden after Hide (twice)")
AssertTrue(!WinExist("ahk_id " hwnd1), "windows destroyed")

; After Hide, double-clicks on our other windows don't fire
probe := Gui()
probe.Show("w100 h100 NA")
PostMessage(WM_LBUTTONDBLCLK, 1, 0, , "ahk_id " probe.Hwnd)
Sleep(100)
AssertEq(unlockCount, 1, "no callback after Hide")
probe.Destroy()

Done()
