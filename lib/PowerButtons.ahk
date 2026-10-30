#Requires AutoHotkey v2.0

; Saves, disables and restores the physical power/sleep button actions of the
; active power scheme. The originals are kept in a state file while disabled,
; so a crash while locked can be repaired on the next start.
class PowerButtons {
    static SubButtons := "{4f971e89-eebd-4455-a8de-9e59040e7347}"
    static Settings := Map(
        "Power", "{7648efa3-dd9c-4e3e-b566-50f929386280}",
        "Sleep", "{96996bc0-ad50-47ec-923b-6f41874dd9eb}")
    static Keys := ["PowerAC", "PowerDC", "SleepAC", "SleepDC"]

    __New(stateFile) {
        this.StateFile := stateFile
    }

    Disable() {
        if !FileExist(this.StateFile) {
            for key, value in PowerButtons.Read()
                IniWrite(value, this.StateFile, "Saved", key)
        }
        PowerButtons.Write(Map("PowerAC", 0, "PowerDC", 0, "SleepAC", 0, "SleepDC", 0))
    }

    Restore() {
        if !FileExist(this.StateFile)
            return false
        values := Map()
        for key in PowerButtons.Keys {
            value := IniRead(this.StateFile, "Saved", key, "")
            if !IsInteger(value) {
                FileDelete(this.StateFile)
                return false
            }
            values[key] := Integer(value)
        }
        PowerButtons.Write(values)
        FileDelete(this.StateFile)
        return true
    }

    static Read() {
        values := Map()
        scheme := PowerButtons._ActiveScheme()
        try {
            sub := PowerButtons._Guid(PowerButtons.SubButtons)
            for name, guid in PowerButtons.Settings {
                setting := PowerButtons._Guid(guid)
                for mode in ["AC", "DC"] {
                    r := DllCall("powrprof\PowerRead" mode "ValueIndex", "Ptr", 0, "Ptr", scheme
                        , "Ptr", sub, "Ptr", setting, "UInt*", &value := 0, "UInt")
                    if r
                        throw OSError(r, "PowerRead" mode "ValueIndex")
                    values[name mode] := value
                }
            }
        } finally {
            DllCall("LocalFree", "Ptr", scheme)
        }
        return values
    }

    static Write(values) {
        scheme := PowerButtons._ActiveScheme()
        try {
            sub := PowerButtons._Guid(PowerButtons.SubButtons)
            for name, guid in PowerButtons.Settings {
                setting := PowerButtons._Guid(guid)
                for mode in ["AC", "DC"] {
                    r := DllCall("powrprof\PowerWrite" mode "ValueIndex", "Ptr", 0, "Ptr", scheme
                        , "Ptr", sub, "Ptr", setting, "UInt", values[name mode], "UInt")
                    if r
                        throw OSError(r, "PowerWrite" mode "ValueIndex")
                }
            }
            r := DllCall("powrprof\PowerSetActiveScheme", "Ptr", 0, "Ptr", scheme, "UInt")
            if r
                throw OSError(r, "PowerSetActiveScheme")
        } finally {
            DllCall("LocalFree", "Ptr", scheme)
        }
    }

    static _ActiveScheme() {
        r := DllCall("powrprof\PowerGetActiveScheme", "Ptr", 0, "Ptr*", &scheme := 0, "UInt")
        if r
            throw OSError(r, "PowerGetActiveScheme")
        return scheme
    }

    static _Guid(str) {
        buf := Buffer(16)
        DllCall("ole32\CLSIDFromString", "WStr", str, "Ptr", buf, "HRESULT")
        return buf
    }
}
