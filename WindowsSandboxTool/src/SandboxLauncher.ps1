# CREATE SandboxLauncher.ps1 RIGHT NOW
$launcherContent = @'
param(
    [string]$FilePath,
    [string]$Input = "",
    [string]$Output = "",
    [switch]$NoNetwork,
    [switch]$ReadOnly,
    [switch]$Help
)

if ($Help) {
    Write-Host "Windows Sandbox Launcher"
    Write-Host "Usage: .\SandboxLauncher.ps1 -FilePath program.exe"
    exit
}

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Test-Path $FilePath)) {
    Write-Host "ERROR: File not found: $FilePath" -ForegroundColor Red
    exit 1
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$configFile = "$scriptPath\..\configs\sandbox_$timestamp.wsb"
if (-not $Output) { $Output = "$scriptPath\..\output\output_$timestamp.txt" }

Write-Host "=== Windows Sandbox Launcher ===" -ForegroundColor Cyan
Write-Host "Program: $FilePath" -ForegroundColor White
Write-Host "Config: $configFile" -ForegroundColor White
Write-Host "Output: $Output" -ForegroundColor White
Write-Host "`nThis is a DEMO. Windows Sandbox will launch when enabled." -ForegroundColor Yellow
Write-Host "Press any key to continue..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
'@

$launcherContent | Out-File -FilePath "C:\WindowsSandboxTool\src\SandboxLauncher.ps1" -Encoding ASCII -Force
Write-Host "✓ CREATED: SandboxLauncher.ps1" -ForegroundColor Green