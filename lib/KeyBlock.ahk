#Requires AutoHotkey v2.0

; Swallows every keystroke while active. The mouse is not affected.
class KeyBlock {
    __New() {
        this._hook := InputHook("L0")
        this._hook.VisibleText := false
        this._hook.VisibleNonText := false
        this._hook.KeyOpt("{All}", "S")
    }

    IsActive => this._hook.InProgress

    Start() {
        if !this._hook.InProgress
            this._hook.Start()
    }

    Stop() {
        if this._hook.InProgress
            this._hook.Stop()
    }
}
