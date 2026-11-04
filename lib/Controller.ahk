#Requires AutoHotkey v2.0

; Owns the locked/paused state and drives the keyboard block, overlay and power
; buttons in a fixed order. Power-button errors never stop the keyboard lock.
class CatKeyController {
    __New(timeoutMs, overlay, keyBlock, powerButtons) {
        this.TimeoutMs := timeoutMs
        this.Overlay := overlay
        this.KeyBlock := keyBlock
        this.PowerButtons := powerButtons
        this.Locked := false
        this.Paused := false
        this.LastError := ""
        this.SessionLocked := false
        this.Now := () => A_TickCount
        this._idleSince := ""  ; tick of the last session unlock
        overlay.OnUnlock := ObjBindMethod(this, "Unlock")
    }

    ; Called once a second with A_TimeIdlePhysical.
    Tick(idleMs) {
        if this.Locked {
            this.Overlay.KeepOnTop()
            return
        }
        if this.Paused || this.SessionLocked
            return
        ; Input on the lock screen may not reach our hook, so idle can't be
        ; older than the last session unlock
        if this._idleSince != ""
            idleMs := Min(idleMs, this.Now.Call() - this._idleSince)
        if idleMs >= this.TimeoutMs
            this.Lock()
    }

    ; Windows lock screen: release everything so the PIN can be typed, and
    ; don't lock again until the session is unlocked.
    OnSessionLock() {
        this.SessionLocked := true
        this.Unlock()
    }

    OnSessionUnlock() {
        this.SessionLocked := false
        this._idleSince := this.Now.Call()
    }

    Lock() {
        if this.Locked
            return
        this.Locked := true
        this.KeyBlock.Start()
        shown := false
        try {
            this.Overlay.Show()
            shown := this.Overlay.IsShown
        } catch as e {
            this.LastError := e.Message
        }
        ; No (complete) overlay means nothing reliable to double-click: don't
        ; leave the keyboard blocked
        if !shown {
            this.Overlay.Hide()
            this.KeyBlock.Stop()
            this.Locked := false
            return
        }
        try {
            this.PowerButtons.Disable()
        } catch as e {
            this.LastError := e.Message
        }
    }

    Unlock() {
        if !this.Locked
            return
        this.Locked := false
        this.Overlay.Hide()
        this.KeyBlock.Stop()
        try {
            this.PowerButtons.Restore()
        } catch as e {
            this.LastError := e.Message
        }
    }

    TogglePause() {
        this.Paused := !this.Paused
        return this.Paused
    }

    ; Repairs button actions left disabled by a crash while locked.
    RecoverFromCrash() {
        try {
            this.PowerButtons.Restore()
        } catch as e {
            this.LastError := e.Message
        }
    }

    Shutdown() => this.Unlock()
}
