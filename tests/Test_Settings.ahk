#Requires AutoHotkey v2.0
#Include %A_ScriptDir%\Assert.ahk
#Include %A_ScriptDir%\..\lib\Settings.ahk

ini := A_Temp "\CatKey.test.ini"

WriteIni(text) {
    if FileExist(ini)
        FileDelete(ini)
    FileAppend(text, ini, "UTF-16")
}

try {
    ; Missing file: created with defaults
    if FileExist(ini)
        FileDelete(ini)
    s := Settings(ini)
    AssertTrue(FileExist(ini), "missing file is created")
    AssertEq(s.IdleTimeoutMin, 3, "default timeout")
    AssertEq(s.OverlayText, "CatKey locked", "default text")
    AssertEq(IniRead(ini, "CatKey", "IdleTimeoutMin"), "3", "file holds default timeout")
    AssertEq(IniRead(ini, "CatKey", "OverlayText"), "CatKey locked", "file holds default text")

    ; Existing file: values read, not overwritten
    WriteIni("[CatKey]`nIdleTimeoutMin=0.5`nOverlayText=Pisică 🐱`n")
    s := Settings(ini)
    AssertEq(s.IdleTimeoutMin, "0.5", "custom timeout")
    AssertEq(s.OverlayText, "Pisică 🐱", "custom unicode text")

    ; Invalid timeouts fall back to the default
    for bad in ["abc", "0", "-2", ""] {
        WriteIni("[CatKey]`nIdleTimeoutMin=" bad "`n")
        AssertEq(Settings(ini).IdleTimeoutMin, 3, "timeout '" bad "' falls back")
    }

    ; Missing keys fall back to the defaults
    WriteIni("[CatKey]`n")
    s := Settings(ini)
    AssertEq(s.IdleTimeoutMin, 3, "missing timeout key")
    AssertEq(s.OverlayText, "CatKey locked", "missing text key")
} finally {
    if FileExist(ini)
        FileDelete(ini)
}
Done()
