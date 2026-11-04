#Requires AutoHotkey v2.0

; Runs the script at Windows sign-in through the current user's Run registry key.
; Enabled only counts when the entry launches this script from where it is now,
; so moving the script shows it as disabled until it is enabled again.
class Autostart {
    static RunKey := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"

    __New(name := "CatKey") {
        this.Name := name
        this.Command := A_IsCompiled
            ? '"' A_ScriptFullPath '"'
            : '"' A_AhkPath '" "' A_ScriptFullPath '"'
    }

    IsEnabled() {
        try return RegRead(Autostart.RunKey, this.Name) = this.Command
        return false
    }

    Enable() => RegWrite(this.Command, "REG_SZ", Autostart.RunKey, this.Name)

    Disable() {
        try RegDelete(Autostart.RunKey, this.Name)
    }

    ; Returns the new state
    Toggle() {
        if this.IsEnabled()
            this.Disable()
        else
            this.Enable()
        return this.IsEnabled()
    }
}
