#Requires AutoHotkey v2.0
#SingleInstance Off

; Minimal assertion helpers. Results go to stdout; Done() sets the exit code.
global Failures := 0

; Unhandled errors print and exit instead of showing a blocking dialog
OnError((e, *) => (FileAppend("ERROR " e.Message " (line " e.Line ")`n", "*"), ExitApp(2)))

AssertEq(actual, expected, name) {
    global Failures
    if (actual == expected) {
        FileAppend("PASS " name "`n", "*")
    } else {
        Failures += 1
        FileAppend("FAIL " name " (expected '" expected "', got '" actual "')`n", "*")
    }
}

AssertTrue(cond, name) => AssertEq(!!cond, 1, name)

Done() {
    global Failures
    ExitApp(Failures ? 1 : 0)
}
