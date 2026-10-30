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

    ; Second Disable must not overwrite the saved originals with zeros
    pb.Disable()
    AssertEq(Integer(IniRead(stateFile, "Saved", "PowerDC")), original["PowerDC"], "second Disable keeps originals")

    ; Restore puts originals back and deletes the file
    AssertEq(pb.Restore(), true, "Restore returns true")
    now := PowerButtons.Read()
    for key in ["PowerAC", "PowerDC", "SleepAC", "SleepDC"]
        AssertEq(now[key], original[key], "Restore brings back " key)
    AssertTrue(!FileExist(stateFile), "Restore deletes state file")

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
Done()
