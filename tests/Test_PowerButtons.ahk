#Requires AutoHotkey v2.0
#Include %A_ScriptDir%\Assert.ahk
#Include %A_ScriptDir%\..\lib\PowerButtons.ahk

stateFile := A_Temp "\CatKey.test.state"
if FileExist(stateFile)
    FileDelete(stateFile)

original := PowerButtons.Read()
try {
    for key in ["PowerAC", "PowerDC", "SleepAC", "SleepDC"]
        AssertTrue(IsInteger(original[key]), "Read returns integer " key)

    pb := PowerButtons(stateFile)

    ; Restore with no state file does nothing
    AssertEq(pb.Restore(), false, "Restore without state file returns false")

    ; Disable zeroes everything and saves originals
    pb.Disable()
    now := PowerButtons.Read()
    for key in ["PowerAC", "PowerDC", "SleepAC", "SleepDC"]
        AssertEq(now[key], 0, "Disable sets " key " to 0")
    AssertTrue(FileExist(stateFile), "Disable creates state file")
    AssertEq(Integer(IniRead(stateFile, "Saved", "PowerAC")), original["PowerAC"], "state file holds original PowerAC")

    AssertEq(IniRead(stateFile, "Saved", "Scheme", ""), PowerButtons.ActiveSchemeGuid(), "state file records the active scheme")

    ; Second Disable must not overwrite the saved originals with zeros
    pb.Disable()
    AssertEq(Integer(IniRead(stateFile, "Saved", "PowerDC")), original["PowerDC"], "second Disable keeps originals")

    ; Restore puts originals back and deletes the file
    AssertEq(pb.Restore(), true, "Restore returns true")
    now := PowerButtons.Read()
    for key in ["PowerAC", "PowerDC", "SleepAC", "SleepDC"]
        AssertEq(now[key], original[key], "Restore brings back " key)
    AssertTrue(!FileExist(stateFile), "Restore deletes state file")

    ; State file without a Scheme (written by an earlier CatKey) restores to the active scheme
    PowerButtons.Write(Map("PowerAC", 0, "PowerDC", 0, "SleepAC", 0, "SleepDC", 0))
    for key in ["PowerAC", "PowerDC", "SleepAC", "SleepDC"]
        IniWrite(original[key], stateFile, "Saved", key)
    AssertEq(pb.Restore(), true, "state file without Scheme: Restore returns true")
    AssertEq(PowerButtons.Read()["PowerDC"], original["PowerDC"], "state file without Scheme: restored to active scheme")
    AssertTrue(!FileExist(stateFile), "state file without Scheme: file deleted")

    ; Malformed Scheme counts as corrupt
    for key in ["PowerAC", "PowerDC", "SleepAC", "SleepDC"]
        IniWrite(original[key], stateFile, "Saved", key)
    IniWrite("not-a-guid", stateFile, "Saved", "Scheme")
    AssertEq(pb.Restore(), false, "malformed Scheme: Restore returns false")

    ; Corrupt state file: no exception, file removed, settings untouched
    IniWrite("abc", stateFile, "Saved", "PowerAC")
    AssertEq(pb.Restore(), false, "corrupt state file: Restore returns false")
    AssertTrue(!FileExist(stateFile), "corrupt state file: file deleted")
    AssertEq(PowerButtons.Read()["PowerAC"], original["PowerAC"], "corrupt state file: settings untouched")
} finally {
    PowerButtons.Write(original)
    if FileExist(stateFile)
        FileDelete(stateFile)
}

; Restore writes to the scheme the values were saved from, even if the user
; switched plans meanwhile, and leaves the active scheme alone.
tmpOut := A_Temp "\CatKey.test.scheme.txt"
RunWait(A_ComSpec ' /c powercfg /duplicatescheme SCHEME_CURRENT > "' tmpOut '"', , "Hide")
RegExMatch(FileRead(tmpOut), "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}", &m)
FileDelete(tmpOut)
otherScheme := "{" m[0] "}"
activeBefore := PowerButtons.ActiveSchemeGuid()
try {
    PowerButtons.Write(Map("PowerAC", 0, "PowerDC", 0, "SleepAC", 0, "SleepDC", 0), otherScheme)
    IniWrite(otherScheme, stateFile, "Saved", "Scheme")
    for key, value in Map("PowerAC", 3, "PowerDC", 1, "SleepAC", 2, "SleepDC", 1)
        IniWrite(value, stateFile, "Saved", key)
    AssertEq(PowerButtons(stateFile).Restore(), true, "other scheme: Restore returns true")
    other := PowerButtons.Read(otherScheme)
    AssertEq(other["PowerAC"] other["PowerDC"] other["SleepAC"] other["SleepDC"], "3121", "other scheme: values restored there")
    AssertEq(PowerButtons.ActiveSchemeGuid(), activeBefore, "other scheme: active scheme unchanged")
    now := PowerButtons.Read()
    AssertEq(now["PowerAC"], original["PowerAC"], "other scheme: active scheme values untouched")
} finally {
    RunWait('powercfg /delete ' m[0], , "Hide")
    if FileExist(stateFile)
        FileDelete(stateFile)
}
Done()
