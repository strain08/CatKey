#Requires AutoHotkey v2.0
#Include %A_ScriptDir%\Assert.ahk
#Include %A_ScriptDir%\..\lib\Autostart.ahk

name := "CatKey.test"
a := Autostart(name)
a.Disable()
try {
    AssertEq(a.IsEnabled(), false, "disabled at start")
    AssertEq(a.Command, '"' A_AhkPath '" "' A_ScriptFullPath '"', "command runs this script")

    a.Enable()
    AssertEq(a.IsEnabled(), true, "Enable enables")
    AssertEq(RegRead(Autostart.RunKey, name), a.Command, "Run value holds the command")

    a.Disable()
    AssertEq(a.IsEnabled(), false, "Disable disables")
    a.Disable()
    AssertEq(a.IsEnabled(), false, "Disable when disabled is harmless")

    AssertEq(a.Toggle(), true, "Toggle enables")
    AssertEq(a.Toggle(), false, "Toggle disables")

    ; An entry for the script at another location doesn't count as enabled
    RegWrite('"' A_AhkPath '" "C:\elsewhere\CatKey.ahk"', "REG_SZ", Autostart.RunKey, name)
    AssertEq(a.IsEnabled(), false, "stale path is not enabled")
    AssertEq(a.Toggle(), true, "Toggle on stale path re-enables")
    AssertEq(RegRead(Autostart.RunKey, name), a.Command, "stale path replaced")
} finally {
    a.Disable()
}
Done()
