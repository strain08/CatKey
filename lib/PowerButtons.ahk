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
            ; Remember which scheme the values came from: the user may switch
            ; plans (or we may crash) before they are restored.
            scheme := PowerButtons.ActiveSchemeGuid()
            for key, value in PowerButtons.Read(scheme)
                IniWrite(value, this.StateFile, "Saved", key)
            IniWrite(scheme, this.StateFile, "Saved", "Scheme")
        }
        PowerButtons.Write(Map("PowerAC", 0, "PowerDC", 0, "SleepAC", 0, "SleepDC", 0))
    }

    Restore() {
        if !FileExist(this.StateFile)
            return false
        scheme := IniRead(this.StateFile, "Saved", "Scheme", "")
        values := Map()
        for key in PowerButtons.Keys
            values[key] := IniRead(this.StateFile, "Saved", key, "")
        ; No Scheme (file from an earlier CatKey): restore to the active scheme
        validScheme := scheme = "" || RegExMatch(scheme, "i)^\{[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}\}$")
        for key, value in values {
            if !IsInteger(value) || !validScheme {
                FileDelete(this.StateFile)
                return false
            }
            values[key] := Integer(value)
        }
        PowerButtons.Write(values, scheme)
        FileDelete(this.StateFile)
        return true
    }

    ; Returns the active power scheme as "{GUID}".
    static ActiveSchemeGuid() {
        r := DllCall("powrprof\PowerGetActiveScheme", "Ptr", 0, "Ptr*", &pScheme := 0, "UInt")
        if r
            throw OSError(r, "PowerGetActiveScheme")
        buf := Buffer(78)
        DllCall("ole32\StringFromGUID2", "Ptr", pScheme, "Ptr", buf, "Int", 39)
        DllCall("LocalFree", "Ptr", pScheme)
        return StrGet(buf, "UTF-16")
    }

    ; scheme: "{GUID}"; defaults to the active scheme.
    static Read(scheme := "") {
        values := Map()
        schemeBuf := PowerButtons._Guid(scheme = "" ? PowerButtons.ActiveSchemeGuid() : scheme)
        sub := PowerButtons._Guid(PowerButtons.SubButtons)
        for name, guid in PowerButtons.Settings {
            setting := PowerButtons._Guid(guid)
            for mode in ["AC", "DC"] {
                r := DllCall("powrprof\PowerRead" mode "ValueIndex", "Ptr", 0, "Ptr", schemeBuf
                    , "Ptr", sub, "Ptr", setting, "UInt*", &value := 0, "UInt")
                if r
                    throw OSError(r, "PowerRead" mode "ValueIndex")
                values[name mode] := value
            }
        }
        return values
    }

    ; scheme: "{GUID}"; defaults to the active scheme. Changes take effect
    ; immediately only when the scheme is the active one.
    static Write(values, scheme := "") {
        active := PowerButtons.ActiveSchemeGuid()
        if scheme = ""
            scheme := active
        schemeBuf := PowerButtons._Guid(scheme)
        sub := PowerButtons._Guid(PowerButtons.SubButtons)
        for name, guid in PowerButtons.Settings {
            setting := PowerButtons._Guid(guid)
            for mode in ["AC", "DC"] {
                r := DllCall("powrprof\PowerWrite" mode "ValueIndex", "Ptr", 0, "Ptr", schemeBuf
                    , "Ptr", sub, "Ptr", setting, "UInt", values[name mode], "UInt")
                if r
                    throw OSError(r, "PowerWrite" mode "ValueIndex")
            }
        }
        if scheme = active {
            r := DllCall("powrprof\PowerSetActiveScheme", "Ptr", 0, "Ptr", schemeBuf, "UInt")
            if r
                throw OSError(r, "PowerSetActiveScheme")
        }
    }

    static _Guid(str) {
        buf := Buffer(16)
        DllCall("ole32\CLSIDFromString", "WStr", str, "Ptr", buf, "HRESULT")
        return buf
    }
}
