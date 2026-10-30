#Requires AutoHotkey v2.0
#Include %A_ScriptDir%\Assert.ahk
#Include %A_ScriptDir%\..\lib\Controller.ahk

global Calls := []

LogText() {
    s := ""
    for entry in Calls
        s .= entry ","
    return RTrim(s, ",")
}

ResetLog() => Calls.Length := 0

class FakeOverlay {
    OnUnlock := ""
    IsShown := false
    ShowFails := ""  ; "", "throw" or "empty" (no monitors)
    Show() {
        Calls.Push("overlay.Show")
        if this.ShowFails = "throw"
            throw Error("monitor gone")
        this.IsShown := this.ShowFails != "empty"
    }
    Hide() {
        Calls.Push("overlay.Hide")
        this.IsShown := false
    }
    KeepOnTop() => Calls.Push("overlay.KeepOnTop")
}

class FakeKeyBlock {
    Start() => Calls.Push("keys.Start")
    Stop() => Calls.Push("keys.Stop")
}

class FakePower {
    ShouldThrow := false
    Disable() {
        Calls.Push("power.Disable")
        if this.ShouldThrow
            throw Error("access denied")
    }
    Restore() {
        Calls.Push("power.Restore")
        if this.ShouldThrow
            throw Error("access denied")
        return true
    }
}

ov := FakeOverlay(), kb := FakeKeyBlock(), pw := FakePower()
c := CatKeyController(300000, ov, kb, pw)

; Idle below timeout: nothing happens
c.Tick(299999)
AssertEq(LogText(), "", "below timeout does nothing")
AssertEq(c.Locked, false, "not locked below timeout")

; At timeout: lock in order keys -> overlay -> power
c.Tick(300000)
AssertEq(LogText(), "keys.Start,overlay.Show,power.Disable", "lock order at timeout")
AssertEq(c.Locked, true, "locked at timeout")

; Lock is idempotent
ResetLog()
c.Lock()
AssertEq(LogText(), "", "Lock is idempotent")

; Tick while locked keeps overlay on top, doesn't re-lock
c.Tick(999999)
AssertEq(LogText(), "overlay.KeepOnTop", "tick while locked keeps on top")

; Overlay double-click callback unlocks in order overlay -> keys -> power
ResetLog()
ov.OnUnlock.Call()
AssertEq(LogText(), "overlay.Hide,keys.Stop,power.Restore", "OnUnlock unlocks in order")
AssertEq(c.Locked, false, "unlocked")

; Unlock is idempotent
ResetLog()
c.Unlock()
AssertEq(LogText(), "", "Unlock is idempotent")

; Paused: idle doesn't lock, Lock() still works
AssertEq(c.TogglePause(), true, "TogglePause returns true")
c.Tick(999999)
AssertEq(c.Locked, false, "paused: idle does not lock")
c.Lock()
AssertEq(c.Locked, true, "paused: Lock now still locks")
c.Unlock()
AssertEq(c.TogglePause(), false, "TogglePause returns false")

; Power failure must not prevent locking or unlocking
pw.ShouldThrow := true
ResetLog()
c.Lock()
AssertEq(c.Locked, true, "lock survives power failure")
AssertEq(LogText(), "keys.Start,overlay.Show,power.Disable", "keys and overlay engaged despite power failure")
AssertEq(c.LastError, "access denied", "power error recorded")
c.Unlock()
AssertEq(c.Locked, false, "unlock survives power failure")
c.RecoverFromCrash()
AssertTrue(true, "RecoverFromCrash survives power failure")
pw.ShouldThrow := false

; RecoverFromCrash restores buttons
ResetLog()
c.RecoverFromCrash()
AssertEq(LogText(), "power.Restore", "RecoverFromCrash restores")

; Overlay failure must not leave the keyboard blocked with nothing to double-click
for mode in ["throw", "empty"] {
    ov.ShowFails := mode
    ResetLog()
    c.Lock()
    AssertEq(c.Locked, false, "overlay " mode ": lock rolled back")
    AssertEq(LogText(), "keys.Start,overlay.Show,overlay.Hide,keys.Stop", "overlay " mode ": keys released, power untouched")
}
ov.ShowFails := ""

; Shutdown while locked unlocks; while unlocked does nothing
c.Lock()
ResetLog()
c.Shutdown()
AssertEq(LogText(), "overlay.Hide,keys.Stop,power.Restore", "Shutdown unlocks")
ResetLog()
c.Shutdown()
AssertEq(LogText(), "", "Shutdown when unlocked does nothing")

Done()
