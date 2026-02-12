# Create simple setup.ps1
$setupSimple = @"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Windows Sandbox Tool - Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
Write-Host "✓ Execution policy set" -ForegroundColor Green

# Create directories
$dirs = @("configs", "output", "testprograms", "docs", "src\Modules")
foreach ($dir in $dirs) {
    $path = Join-Path $PSScriptRoot $dir
    New-Item -ItemType Directory -Force -Path $path | Out-Null
}
Write-Host "✓ Directories created" -ForegroundColor Green

# Check Windows Sandbox
$sandboxPath = "$env:windir\System32\WindowsSandbox.exe"
if (Test-Path $sandboxPath) {
    Write-Host "✓ Windows Sandbox is installed" -ForegroundColor Green
} else {
    Write-Host "⚠ Windows Sandbox is NOT installed" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Setup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. cd C:\WindowsSandboxTool\src" -ForegroundColor White
Write-Host "2. .\SandboxTool.ps1" -ForegroundColor White
"@

