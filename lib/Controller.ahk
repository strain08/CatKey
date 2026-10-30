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
        overlay.OnUnlock := ObjBindMethod(this, "Unlock")
    }

    ; Called once a second with A_TimeIdlePhysical.
    Tick(idleMs) {
        if this.Locked
            this.Overlay.KeepOnTop()
        else if !this.Paused && idleMs >= this.TimeoutMs
            this.Lock()
    }

    Lock() {
        if this.Locked
            return
        this.Locked := true
        this.KeyBlock.Start()
        this.Overlay.Show()
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
