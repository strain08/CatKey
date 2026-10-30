#Requires AutoHotkey v2.0
#Include %A_ScriptDir%\Assert.ahk
#Include %A_ScriptDir%\..\lib\KeyBlock.ahk

g := Gui()
ed := g.AddEdit("w300")
g.Show()
WinWaitActive("ahk_id " g.Hwnd)
ed.Focus()

kb := KeyBlock()
AssertEq(kb.IsActive, false, "inactive before Start")

kb.Start()
kb.Start()
AssertEq(kb.IsActive, true, "active after Start (twice)")
SendEvent("abc{Space}{Enter}+x1")
Sleep(200)
AssertEq(ed.Value, "", "keys swallowed while active")

kb.Stop()
kb.Stop()
AssertEq(kb.IsActive, false, "inactive after Stop (twice)")
SendEvent("xyz")
Sleep(200)
AssertEq(ed.Value, "xyz", "keys pass after Stop")

kb.Start()
SendEvent("q")
Sleep(200)
AssertEq(ed.Value, "xyz", "restart blocks again")
kb.Stop()

g.Destroy()
Done()
