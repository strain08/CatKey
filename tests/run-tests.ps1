$ahk = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
$failed = 0
foreach ($test in Get-ChildItem "$PSScriptRoot\Test_*.ahk") {
    Write-Output "== $($test.Name)"
    & $ahk /ErrorStdOut $test.FullName 2>&1 | ForEach-Object { Write-Output $_ }
    if ($LASTEXITCODE -ne 0) {
        Write-Output "!! $($test.Name) exited $LASTEXITCODE"
        $failed++
    }
}
if ($failed) { Write-Output "$failed test file(s) failed"; exit 1 }
Write-Output "all tests passed"
