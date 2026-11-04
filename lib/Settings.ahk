#Requires AutoHotkey v2.0

; User settings from an INI file, which is created with defaults if missing.
; Invalid values fall back to the defaults.
class Settings {
    static DefaultTimeoutMin := 3
    static DefaultOverlayText := "CatKey locked"

    __New(path) {
        if !FileExist(path)
            ; UTF-16 so the overlay text can hold any character
            FileAppend(Format("
            (
            ; CatKey settings. Restart CatKey after editing.
            [CatKey]
            ; Minutes of no input before the keyboard locks
            IdleTimeoutMin={1}
            ; Text shown on the dimmed screens while locked
            OverlayText={2}
            )", Settings.DefaultTimeoutMin, Settings.DefaultOverlayText), path, "UTF-16")

        min := IniRead(path, "CatKey", "IdleTimeoutMin", Settings.DefaultTimeoutMin)
        if !IsNumber(min) || min <= 0
            min := Settings.DefaultTimeoutMin
        this.IdleTimeoutMin := min
        this.OverlayText := IniRead(path, "CatKey", "OverlayText", Settings.DefaultOverlayText)
    }
}
