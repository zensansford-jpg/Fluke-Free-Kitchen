# run_all_tests.ps1 — run every Fluke Free Kitchen test suite and print one summary.
#
# Usage (from anywhere):
#   powershell -ExecutionPolicy Bypass -File tools\run_all_tests.ps1
#
# It imports the project first, then runs each suite headless, captures stdout/stderr
# to %TEMP%\opencode\test_runs\<suite>.out.txt, and prints PASS/FAIL per suite.
# The word "PASSED"/"FAILED" in the suite's own output decides the verdict, because
# the Godot console build always reports exit code 0 on Windows.

param(
    [string]$Project = "C:\Users\ASUS\river-dash-safe-feast-run",
    [string]$Godot   = "C:\Users\ASUS\godot-tools\Godot_v4.7.2-stable_win64_console.exe",
    [int]$TimeoutMs  = 900000
)

$ErrorActionPreference = 'Continue'
$tmp = Join-Path $env:TEMP 'opencode\test_runs'
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

if (-not (Test-Path $Godot)) { Write-Host "Godot not found: $Godot" -ForegroundColor Red; exit 2 }
if (-not (Test-Path $Project)) { Write-Host "Project not found: $Project" -ForegroundColor Red; exit 2 }

function Invoke-Suite {
    param([string]$Scene, [string[]]$Extra = @())
    $name = [IO.Path]::GetFileNameWithoutExtension($Scene)
    $out = Join-Path $tmp "$name.out.txt"
    $err = Join-Path $tmp "$name.err.txt"
    $argList = @('--headless', '--path', $Project, $Scene) + $Extra
    $p = Start-Process -FilePath $Godot -ArgumentList $argList -NoNewWindow -PassThru `
        -RedirectStandardOutput $out -RedirectStandardError $err
    $finished = $p.WaitForExit($TimeoutMs)
    if (-not $finished) { try { $p.Kill() } catch {} }
    $text = ''
    if (Test-Path $out) { $text = [string](Get-Content $out -Encoding UTF8 -Raw) }
    $errText = ''
    if ((Test-Path $err) -and ((Get-Item $err).Length -gt 0)) { $errText = [string](Get-Content $err -Encoding UTF8 -Raw) }
    $verdict = 'UNKNOWN'
    if (-not $finished) { $verdict = 'TIMEOUT' }
    elseif ($text -match 'FAILED') { $verdict = 'FAIL' }
    elseif ($text -match 'PASSED') { $verdict = 'PASS' }
    # last meaningful line for the summary
    $detail = ($text -split "`n" | Where-Object { $_ -match 'PASSED|FAILED|problems|layouts' } | Select-Object -Last 1)
    [pscustomobject]@{
        Suite  = $name
        Result = $verdict
        Detail = if ($detail) { $detail.Trim() } else { '' }
        Stderr = if ($errText.Trim().Length -gt 0) { $errText.Trim() } else { '' }
    }
}

Write-Host '== Fluke Free Kitchen — full test run ==' -ForegroundColor Cyan

Write-Host '[import] res:// ...'
$imp = Start-Process -FilePath $Godot -ArgumentList @('--headless','--path',$Project,'--import') -NoNewWindow -PassThru `
    -RedirectStandardOutput (Join-Path $tmp 'import.out.txt') -RedirectStandardError (Join-Path $tmp 'import.err.txt')
if (-not $imp.WaitForExit(600000)) { try { $imp.Kill() } catch {} }

$suites = @(
    'res://tests/smoke_test.tscn',
    'res://tests/flow_test.tscn',
    'res://tests/behaviour_test.tscn',
    'res://tests/cook_test.tscn',
    'res://tests/responsive_check.tscn'
)

$results = foreach ($s in $suites) {
    Write-Host "[run] $s"
    Invoke-Suite -Scene $s
}

Write-Host ''
Write-Host '== SUMMARY ==' -ForegroundColor Cyan
$results | ForEach-Object {
    $colour = switch ($_.Result) { 'PASS' { 'Green' } 'FAIL' { 'Red' } default { 'Yellow' } }
    Write-Host ("{0,-6} {1,-20} {2}" -f $_.Result, $_.Suite, $_.Detail) -ForegroundColor $colour
    if ($_.Stderr) { Write-Host ("       stderr: " + $_.Stderr) -ForegroundColor DarkYellow }
}

$failed = @($results | Where-Object { $_.Result -ne 'PASS' }).Count
Write-Host ''
Write-Host ("$($results.Count - $failed)/$($results.Count) suites passed.") `
    -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })
Write-Host "Raw logs: $tmp"
exit $(if ($failed -eq 0) { 0 } else { 1 })
