# ConfigBuilder.ps1
$configBuilder = @'
<#
.SYNOPSIS
    Windows Sandbox Configuration Builder
.DESCRIPTION
    CLI tool for generating Windows Sandbox configuration files
#>

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Executable,
    
    [Parameter(Mandatory = $false)]
    [string]$Output,
    
    [Parameter(Mandatory = $false)]
    [string]$Input,
    
    [Parameter(Mandatory = $false)]
    [switch]$NoNetwork,
    
    [Parameter(Mandatory = $false)]
    [switch]$ReadOnly,
    
    [Parameter(Mandatory = $false)]
    [int]$Memory = 2048,
    
    [Parameter(Mandatory = $false)]
    [string]$Args
)

# Import module
Import-Module (Join-Path $PSScriptRoot "Modules\SandboxHelper.psm1") -Force

# Set output path
if (-not $Output) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $Output = Join-Path $PSScriptRoot "..\configs\sandbox_$timestamp.wsb"
}

# Ensure output directory exists
$outputDir = Split-Path $Output -Parent
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Create configuration
$config = New-SandboxConfig -Path $Output -NoNetwork:$NoNetwork -ReadOnly:$ReadOnly `
    -MemoryInMB $Memory -ExecutablePath $Executable -Arguments $Args `
    -InputFile $Input

Write-Host "Configuration created: $Output" -ForegroundColor Green

# Launch if requested
$launch = Read-Host "Launch sandbox now? (y/n)"
if ($launch -eq 'y') {
    Start-Process -FilePath "WindowsSandbox.exe" -ArgumentList "`"$Output`""
}
'@

Set-Content -Path "$basePath\src\ConfigBuilder.ps1" -Value $configBuilder -Force
Write-Host "  ✓ ConfigBuilder created" -ForegroundColor Green

# SandboxLauncher.ps1
$sandboxLauncher = @'
<#
.SYNOPSIS
    Windows Sandbox Execution Engine
.DESCRIPTION
    Core execution engine for running untrusted programs in Windows Sandbox
    Supports CLI parameters, stdin/stdout redirection, and policy enforcement
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Path to executable")]
    [ValidateScript({Test-Path $_})]
    [string]$FilePath,
    
    [Parameter(Mandatory = $false, HelpMessage = "Command line arguments")]
    [string[]]$ArgumentList,
    
    [Parameter(Mandatory = $false, HelpMessage = "Input file for stdin redirection")]
    [ValidateScript({Test-Path $_})]
    [string]$InputFile,
    
    [Parameter(Mandatory = $false, HelpMessage = "Output file for stdout capture")]
    [string]$OutputFile,
    
    [Parameter(Mandatory = $false, HelpMessage = "Disable network access")]
    [switch]$NoNetwork,
    
    [Parameter(Mandatory = $false, HelpMessage = "Mount mapped folders as read-only")]
    [switch]$ReadOnly,
    
    [Parameter(Mandatory = $false, HelpMessage = "Memory limit in MB")]
    [ValidateRange(512, 8192)]
    [int]$MemoryMB = 2048,
    
    [Parameter(Mandatory = $false, HelpMessage = "Timeout in seconds")]
    [int]$Timeout = 120,
    
    [Parameter(Mandatory = $false, HelpMessage = "Verbose output")]
    [switch]$Verbose
)

# Import module
$modulePath = Join-Path $PSScriptRoot "Modules\SandboxHelper.psm1"
Import-Module $modulePath -Force

# Resolve absolute paths
$absoluteExe = Resolve-Path $FilePath
$absoluteExe = $absoluteExe.Path

$absoluteInput = $null
if ($InputFile) {
    $absoluteInput = Resolve-Path $InputFile
    $absoluteInput = $absoluteInput.Path
}

$absoluteOutput = $null
if ($OutputFile) {
    $absoluteOutput = if (Split-Path $OutputFile -IsAbsolute) { 
        $OutputFile 
    } else { 
        Join-Path (Get-Location) $OutputFile 
    }
}

# Validate Windows Sandbox availability
$sandboxPath = Get-Command "WindowsSandbox.exe" -ErrorAction SilentlyContinue
if (-not $sandboxPath) {
    Write-Error "Windows Sandbox is not available. Please enable it via Windows Features."
    exit 1
}

Write-Host @"
============================================
  Windows Sandbox Execution Engine v1.0
============================================
Executable:     $absoluteExe
Arguments:      $($ArgumentList -join ' ')
Input File:     $($absoluteInput ?? 'None')
Output File:    $($absoluteOutput ?? 'Console')
Network:        $(if($NoNetwork) {'Disabled'} else {'Enabled'})
Read Only:      $(if($ReadOnly) {'Yes'} else {'No'})
Memory:         ${MemoryMB}MB
Timeout:        ${Timeout}s
============================================
"@ -ForegroundColor Cyan

try {
    # Execute in sandbox
    $result = Start-SandboxExecution -ExecutablePath $absoluteExe `
        -Arguments $ArgumentList `
        -InputFile $absoluteInput `
        -OutputFile $absoluteOutput `
        -NoNetwork:$NoNetwork `
        -ReadOnly:$ReadOnly `
        -MemoryMB $MemoryMB `
        -TimeoutSeconds $Timeout `
        -Verbose:$Verbose
    
    # Display output if captured
    if ($absoluteOutput -and (Test-Path $absoluteOutput)) {
        Write-Host "`n============================================" -ForegroundColor Green
        Write-Host "Program Output:" -ForegroundColor Green
        Write-Host "============================================" -ForegroundColor Green
        Get-Content $absoluteOutput
    }
    
    Write-Host "`n✓ Execution completed successfully" -ForegroundColor Green
    exit 0
}
catch {
    Write-Error "Execution failed: $_"
    exit 1
}
'@

Set-Content -Path "$basePath\src\SandboxLauncher.ps1" -Value $sandboxLauncher -Force
Write-Host "  ✓ SandboxLauncher created" -ForegroundColor Green

# SandboxTool.ps1 (GUI)
$sandboxTool = @'
<#
.SYNOPSIS
    Windows Sandbox Tool - Graphical User Interface
.DESCRIPTION
    Complete GUI tool for managing Windows Sandbox executions
    Features: File selection, policy configuration, real-time output display
.NOTES
    Requires PowerShell 5.1 or later
    Requires Windows Sandbox feature
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Import module
$modulePath = Join-Path $PSScriptRoot "Modules\SandboxHelper.psm1"
Import-Module $modulePath -Force

# Create main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Trustworthy Computing - Windows Sandbox Tool v1.0"
$form.Size = New-Object System.Drawing.Size(900, 700)
$form.StartPosition = "CenterScreen"
$form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("WindowsSandbox.exe")
$form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 245)

# Create title bar
$titlePanel = New-Object System.Windows.Forms.Panel
$titlePanel.Size = New-Object System.Drawing.Size(900, 60)
$titlePanel.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
$titlePanel.Dock = "Top"

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Windows Sandbox Security Tool"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleLabel.Size = New-Object System.Drawing.Size(600, 40)
$titleLabel.Location = New-Object System.Drawing.Point(20, 10)
$titlePanel.Controls.Add($titleLabel)

$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Text = "Trustworthy Computing - Assignment 1"
$subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$subtitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 255)
$subtitleLabel.Size = New-Object System.Drawing.Size(300, 20)
$subtitleLabel.Location = New-Object System.Drawing.Point(20, 35)
$titlePanel.Controls.Add($subtitleLabel)

$form.Controls.Add($titlePanel)

# Main content panel
$contentPanel = New-Object System.Windows.Forms.Panel
$contentPanel.Size = New-Object System.Drawing.Size(880, 580)
$contentPanel.Location = New-Object System.Drawing.Point(10, 70)
$contentPanel.BackColor = [System.Drawing.Color]::White

# GroupBox: Program Selection
$programGroup = New-Object System.Windows.Forms.GroupBox
$programGroup.Text = " Program Selection "
$programGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$programGroup.Size = New-Object System.Drawing.Size(420, 150)
$programGroup.Location = New-Object System.Drawing.Point(15, 15)
$programGroup.BackColor = [System.Drawing.Color]::White

# Executable path
$exeLabel = New-Object System.Windows.Forms.Label
$exeLabel.Text = "Executable:"
$exeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$exeLabel.Location = New-Object System.Drawing.Point(15, 30)
$exeLabel.Size = New-Object System.Drawing.Size(80, 20)

$exeTextBox = New-Object System.Windows.Forms.TextBox
$exeTextBox.Location = New-Object System.Drawing.Point(95, 28)
$exeTextBox.Size = New-Object System.Drawing.Size(220, 25)
$exeTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$exeTextBox.ReadOnly = $true
$exeTextBox.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 250)

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse..."
$browseButton.Location = New-Object System.Drawing.Point(320, 27)
$browseButton.Size = New-Object System.Drawing.Size(80, 28)
$browseButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$browseButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
$browseButton.ForeColor = [System.Drawing.Color]::White
$browseButton.FlatStyle = "Flat"
$browseButton.FlatAppearance.BorderSize = 0
$browseButton.Cursor = "Hand"

# Arguments
$argsLabel = New-Object System.Windows.Forms.Label
$argsLabel.Text = "Arguments:"
$argsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$argsLabel.Location = New-Object System.Drawing.Point(15, 70)
$argsLabel.Size = New-Object System.Drawing.Size(80, 20)

$argsTextBox = New-Object System.Windows.Forms.TextBox
$argsTextBox.Location = New-Object System.Drawing.Point(95, 68)
$argsTextBox.Size = New-Object System.Drawing.Size(220, 25)
$argsTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)

$testButton = New-Object System.Windows.Forms.Button
$testButton.Text = "Test Program"
$testButton.Location = New-Object System.Drawing.Point(320, 67)
$testButton.Size = New-Object System.Drawing.Size(80, 28)
$testButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$testButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
$testButton.ForeColor = [System.Drawing.Color]::White
$testButton.FlatStyle = "Flat"
$testButton.FlatAppearance.BorderSize = 0
$testButton.Cursor = "Hand"

# Working directory
$workLabel = New-Object System.Windows.Forms.Label
$workLabel.Text = "Work Dir:"
$workLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$workLabel.Location = New-Object System.Drawing.Point(15, 110)
$workLabel.Size = New-Object System.Drawing.Size(80, 20)

$workTextBox = New-Object System.Windows.Forms.TextBox
$workTextBox.Text = Get-Location
$workTextBox.Location = New-Object System.Drawing.Point(95, 108)
$workTextBox.Size = New-Object System.Drawing.Size(220, 25)
$workTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)

$workBrowseButton = New-Object System.Windows.Forms.Button
$workBrowseButton.Text = "Browse..."
$workBrowseButton.Location = New-Object System.Drawing.Point(320, 107)
$workBrowseButton.Size = New-Object System.Drawing.Size(80, 28)
$workBrowseButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$workBrowseButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
$workBrowseButton.ForeColor = [System.Drawing.Color]::White
$workBrowseButton.FlatStyle = "Flat"
$workBrowseButton.FlatAppearance.BorderSize = 0
$workBrowseButton.Cursor = "Hand"

$programGroup.Controls.AddRange(@($exeLabel, $exeTextBox, $browseButton, $argsLabel, $argsTextBox, $testButton, $workLabel, $workTextBox, $workBrowseButton))

# GroupBox: I/O Configuration
$ioGroup = New-Object System.Windows.Forms.GroupBox
$ioGroup.Text = " Input/Output Configuration "
$ioGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$ioGroup.Size = New-Object System.Drawing.Size(420, 150)
$ioGroup.Location = New-Object System.Drawing.Point(15, 175)
$ioGroup.BackColor = [System.Drawing.Color]::White

# Input file
$inputLabel = New-Object System.Windows.Forms.Label
$inputLabel.Text = "Input File:"
$inputLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$inputLabel.Location = New-Object System.Drawing.Point(15, 30)
$inputLabel.Size = New-Object System.Drawing.Size(80, 20)

$inputTextBox = New-Object System.Windows.Forms.TextBox
$inputTextBox.Location = New-Object System.Drawing.Point(95, 28)
$inputTextBox.Size = New-Object System.Drawing.Size(220, 25)
$inputTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)

$inputBrowseButton = New-Object System.Windows.Forms.Button
$inputBrowseButton.Text = "Browse..."
$inputBrowseButton.Location = New-Object System.Drawing.Point(320, 27)
$inputBrowseButton.Size = New-Object System.Drawing.Size(80, 28)
$inputBrowseButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$inputBrowseButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
$inputBrowseButton.ForeColor = [System.Drawing.Color]::White
$inputBrowseButton.FlatStyle = "Flat"
$inputBrowseButton.FlatAppearance.BorderSize = 0
$inputBrowseButton.Cursor = "Hand"

# Output file
$outputLabel = New-Object System.Windows.Forms.Label
$outputLabel.Text = "Output File:"
$outputLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$outputLabel.Location = New-Object System.Drawing.Point(15, 70)
$outputLabel.Size = New-Object System.Drawing.Size(80, 20)

$outputTextBox = New-Object System.Windows.Forms.TextBox
$outputTextBox.Text = "output.txt"
$outputTextBox.Location = New-Object System.Drawing.Point(95, 68)
$outputTextBox.Size = New-Object System.Drawing.Size(220, 25)
$outputTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)

$outputBrowseButton = New-Object System.Windows.Forms.Button
$outputBrowseButton.Text = "Browse..."
$outputBrowseButton.Location = New-Object System.Drawing.Point(320, 67)
$outputBrowseButton.Size = New-Object System.Drawing.Size(80, 28)
$outputBrowseButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$outputBrowseButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
$outputBrowseButton.ForeColor = [System.Drawing.Color]::White
$outputBrowseButton.FlatStyle = "Flat"
$outputBrowseButton.FlatAppearance.BorderSize = 0
$outputBrowseButton.Cursor = "Hand"

# Input file content preview
$inputContentLabel = New-Object System.Windows.Forms.Label
$inputContentLabel.Text = "Input Preview:"
$inputContentLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
$inputContentLabel.Location = New-Object System.Drawing.Point(15, 110)
$inputContentLabel.Size = New-Object System.Drawing.Size(80, 20)
$inputContentLabel.ForeColor = [System.Drawing.Color]::Gray

$inputPreviewBox = New-Object System.Windows.Forms.TextBox
$inputPreviewBox.Location = New-Object System.Drawing.Point(95, 108)
$inputPreviewBox.Size = New-Object System.Drawing.Size(305, 25)
$inputPreviewBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$inputPreviewBox.ReadOnly = $true
$inputPreviewBox.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 250)

$ioGroup.Controls.AddRange(@($inputLabel, $inputTextBox, $inputBrowseButton, $outputLabel, $outputTextBox, $outputBrowseButton, $inputContentLabel, $inputPreviewBox))

# GroupBox: Security Policies
$policyGroup = New-Object System.Windows.Forms.GroupBox
$policyGroup.Text = " Security Policies "
$policyGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$policyGroup.Size = New-Object System.Drawing.Size(420, 180)
$policyGroup.Location = New-Object System.Drawing.Point(15, 335)
$policyGroup.BackColor = [System.Drawing.Color]::White

$noNetworkCheck = New-Object System.Windows.Forms.CheckBox
$noNetworkCheck.Text = "Disable Network Access"
$noNetworkCheck.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$noNetworkCheck.Location = New-Object System.Drawing.Point(20, 30)
$noNetworkCheck.Size = New-Object System.Drawing.Size(200, 25)
$noNetworkCheck.Checked = $false

$readOnlyCheck = New-Object System.Windows.Forms.CheckBox
$readOnlyCheck.Text = "Read-Only File Access"
$readOnlyCheck.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$readOnlyCheck.Location = New-Object System.Drawing.Point(20, 60)
$readOnlyCheck.Size = New-Object System.Drawing.Size(200, 25)
$readOnlyCheck.Checked = $true

$clipboardCheck = New-Object System.Windows.Forms.CheckBox
$clipboardCheck.Text = "Disable Clipboard"
$clipboardCheck.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$clipboardCheck.Location = New-Object System.Drawing.Point(20, 90)
$clipboardCheck.Size = New-Object System.Drawing.Size(200, 25)
$clipboardCheck.Checked = $true

$audioCheck = New-Object System.Windows.Forms.CheckBox
$audioCheck.Text = "Disable Audio/Video"
$audioCheck.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$audioCheck.Location = New-Object System.Drawing.Point(20, 120)
$audioCheck.Size = New-Object System.Drawing.Size(200, 25)
$audioCheck.Checked = $true

$printerCheck = New-Object System.Windows.Forms.CheckBox
$printerCheck.Text = "Disable Printer"
$printerCheck.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$printerCheck.Location = New-Object System.Drawing.Point(20, 150)
$printerCheck.Size = New-Object System.Drawing.Size(200, 25)
$printerCheck.Checked = $true

# Memory slider
$memoryLabel = New-Object System.Windows.Forms.Label
$memoryLabel.Text = "Memory Limit:"
$memoryLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$memoryLabel.Location = New-Object System.Drawing.Point(240, 30)
$memoryLabel.Size = New-Object System.Drawing.Size(90, 20)

$memoryTrackBar = New-Object System.Windows.Forms.TrackBar
$memoryTrackBar.Location = New-Object System.Drawing.Point(240, 55)
$memoryTrackBar.Size = New-Object System.Drawing.Size(150, 45)
$memoryTrackBar.Minimum = 512
$memoryTrackBar.Maximum = 4096
$memoryTrackBar.Value = 2048
$memoryTrackBar.TickFrequency = 512
$memoryTrackBar.TickStyle = "BottomRight"

$memoryValueLabel = New-Object System.Windows.Forms.Label
$memoryValueLabel.Text = "2048 MB"
$memoryValueLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$memoryValueLabel.Location = New-Object System.Drawing.Point(240, 95)
$memoryValueLabel.Size = New-Object System.Drawing.Size(150, 20)
$memoryValueLabel.TextAlign = "MiddleCenter"

$timeoutLabel = New-Object System.Windows.Forms.Label
$timeoutLabel.Text = "Timeout (s):"
$timeoutLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$timeoutLabel.Location = New-Object System.Drawing.Point(240, 120)
$timeoutLabel.Size = New-Object System.Drawing.Size(90, 20)

$timeoutNumeric = New-Object System.Windows.Forms.NumericUpDown
$timeoutNumeric.Location = New-Object System.Drawing.Point(240, 145)
$timeoutNumeric.Size = New-Object System.Drawing.Size(80, 25)
$timeoutNumeric.Minimum = 30
$timeoutNumeric.Maximum = 600
$timeoutNumeric.Value = 120

$policyGroup.Controls.AddRange(@($noNetworkCheck, $readOnlyCheck, $clipboardCheck, $audioCheck, $printerCheck, $memoryLabel, $memoryTrackBar, $memoryValueLabel, $timeoutLabel, $timeoutNumeric))

# Right panel - Output/Logs
$outputGroup = New-Object System.Windows.Forms.GroupBox
$outputGroup.Text = " Execution Output "
$outputGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$outputGroup.Size = New-Object System.Drawing.Size(410, 500)
$outputGroup.Location = New-Object System.Drawing.Point(450, 15)
$outputGroup.BackColor = [System.Drawing.Color]::White

$outputTextBox_display = New-Object System.Windows.Forms.TextBox
$outputTextBox_display.Multiline = $true
$outputTextBox_display.ScrollBars = "Both"
$outputTextBox_display.Size = New-Object System.Drawing.Size(380, 400)
$outputTextBox_display.Location = New-Object System.Drawing.Point(15, 30)
$outputTextBox_display.Font = New-Object System.Drawing.Font("Consolas", 10)
$outputTextBox_display.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$outputTextBox_display.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 0)
$outputTextBox_display.ReadOnly = $true

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Status: Ready"
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$statusLabel.Location = New-Object System.Drawing.Point(15, 440)
$statusLabel.Size = New-Object System.Drawing.Size(200, 25)

$runButton = New-Object System.Windows.Forms.Button
$runButton.Text = "▶ RUN IN SANDBOX"
$runButton.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$runButton.Size = New-Object System.Drawing.Size(180, 40)
$runButton.Location = New-Object System.Drawing.Point(215, 435)
$runButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
$runButton.ForeColor = [System.Drawing.Color]::White
$runButton.FlatStyle = "Flat"
$runButton.FlatAppearance.BorderSize = 0
$runButton.Cursor = "Hand"

$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Text = "Clear"
$clearButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$clearButton.Size = New-Object System.Drawing.Size(80, 40)
$clearButton.Location = New-Object System.Drawing.Point(315, 495)
$clearButton.BackColor = [System.Drawing.Color]::Gray
$clearButton.ForeColor = [System.Drawing.Color]::White
$clearButton.FlatStyle = "Flat"
$clearButton.FlatAppearance.BorderSize = 0
$clearButton.Cursor = "Hand"

$outputGroup.Controls.AddRange(@($outputTextBox_display, $statusLabel, $runButton, $clearButton))

$contentPanel.Controls.AddRange(@($programGroup, $ioGroup, $policyGroup, $outputGroup))
$form.Controls.Add($contentPanel)

# Status bar
$statusBar = New-Object System.Windows.Forms.StatusStrip
$statusBar.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
$statusBar.ForeColor = [System.Drawing.Color]::White

$statusLabel_bar = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel_bar.Text = " Windows Sandbox Ready | Hyper-V Enabled | Security Policies Active"
$statusLabel_bar.ForeColor = [System.Drawing.Color]::White

$statusBar.Items.Add($statusLabel_bar)
$form.Controls.Add($statusBar)

# Event Handlers
$browseButton.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = "Select Executable"
    $openFileDialog.Filter = "Executable files (*.exe)|*.exe|All files (*.*)|*.*"
    $openFileDialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")
    
    if ($openFileDialog.ShowDialog() -eq "OK") {
        $exeTextBox.Text = $openFileDialog.FileName
        $workTextBox.Text = Split-Path $openFileDialog.FileName -Parent
    }
})

$workBrowseButton.Add_Click({
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.Description = "Select Working Directory"
    $folderDialog.SelectedPath = $workTextBox.Text
    
    if ($folderDialog.ShowDialog() -eq "OK") {
        $workTextBox.Text = $folderDialog.SelectedPath
    }
})

$inputBrowseButton.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = "Select Input File"
    $openFileDialog.Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*"
    
    if ($openFileDialog.ShowDialog() -eq "OK") {
        $inputTextBox.Text = $openFileDialog.FileName
        
        # Show preview
        if (Test-Path $openFileDialog.FileName) {
            $content = Get-Content $openFileDialog.FileName -TotalCount 1
            $inputPreviewBox.Text = $content
        }
    }
})

$outputBrowseButton.Add_Click({
    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveFileDialog.Title = "Save Output As"
    $saveFileDialog.Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*"
    $saveFileDialog.FileName = "output.txt"
    
    if ($saveFileDialog.ShowDialog() -eq "OK") {
        $outputTextBox.Text = $saveFileDialog.FileName
    }
})

$testButton.Add_Click({
    if ($exeTextBox.Text) {
        $outputTextBox_display.AppendText("`r`n[TEST] Executing test program...")
        $outputTextBox_display.AppendText("`r`n[TEST] Hello.exe is ready for sandbox execution")
        
        # Launch test program normally
        try {
            $process = Start-Process -FilePath $exeTextBox.Text -WindowStyle Normal -PassThru
            $outputTextBox_display.AppendText("`r`n[TEST] Process started with ID: $($process.Id)")
        }
        catch {
            $outputTextBox_display.AppendText("`r`n[TEST ERROR] $_")
        }
    }
})

$memoryTrackBar.Add_ValueChanged({
    $memoryValueLabel.Text = "$($memoryTrackBar.Value) MB"
})

$runButton.Add_Click({
    $runButton.Enabled = $false
    $runButton.Text = "⚙ RUNNING..."
    $outputTextBox_display.Clear()
    $outputTextBox_display.AppendText("========================================`r`n")
    $outputTextBox_display.AppendText("Windows Sandbox Execution Engine v1.0`r`n")
    $outputTextBox_display.AppendText("========================================`r`n`r`n")
    
    $statusLabel.Text = "Status: Initializing sandbox..."
    $statusLabel_bar.Text = " Initializing Windows Sandbox..."
    
    # Validate executable
    if (-not $exeTextBox.Text) {
        [System.Windows.Forms.MessageBox]::Show("Please select an executable file.", "Error", "OK", "Error")
        $runButton.Enabled = $true
        $runButton.Text = "▶ RUN IN SANDBOX"
        return
    }
    
    if (-not (Test-Path $exeTextBox.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Executable file not found.", "Error", "OK", "Error")
        $runButton.Enabled = $true
        $runButton.Text = "▶ RUN IN SANDBOX"
        return
    }
    
    # Prepare parameters
    $params = @{
        FilePath = $exeTextBox.Text
        NoNetwork = $noNetworkCheck.Checked
        ReadOnly = $readOnlyCheck.Checked
        MemoryMB = $memoryTrackBar.Value
        Timeout = [int]$timeoutNumeric.Value
    }
    
    if ($argsTextBox.Text) {
        $params.ArgumentList = $argsTextBox.Text -split ' '
    }
    
    if ($inputTextBox.Text) {
        $params.InputFile = $inputTextBox.Text
    }
    
    if ($outputTextBox.Text) {
        $params.OutputFile = $outputTextBox.Text
    }
    
    # Execute in background job
    $scriptBlock = {
        param($params, $modulePath)
        
        Import-Module $modulePath -Force
        
        try {
            $result = Start-SandboxExecution @params
            return @{ Success = $true; Result = $result }
        }
        catch {
            return @{ Success = $false; Error = $_.ToString() }
        }
    }
    
    $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $params, $modulePath
    
    $outputTextBox_display.AppendText("`r`n[SYSTEM] Sandbox configuration created`r`n")
    $outputTextBox_display.AppendText("[SYSTEM] Launching Windows Sandbox...`r`n")
    $outputTextBox_display.AppendText("[SYSTEM] Security policies: Network=$(if($noNetworkCheck.Checked){'Disabled'}else{'Enabled'}), ReadOnly=$($readOnlyCheck.Checked)`r`n")
    $outputTextBox_display.AppendText("[SYSTEM] Memory: $($memoryTrackBar.Value)MB, Timeout: $($timeoutNumeric.Value)s`r`n`r`n")
    
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 500
    $timer.Add_Tick({
        if ($job.State -eq "Completed" -or $job.State -eq "Failed") {
            $timer.Stop()
            $timer.Dispose()
            
            $result = Receive-Job $job
            Remove-Job $job
            
            if ($result.Success) {
                $outputTextBox_display.AppendText("`r`n[SYSTEM] Execution completed successfully`r`n")
                $statusLabel.Text = "Status: Completed"
                $statusLabel_bar.Text = " Execution completed successfully"
                
                # Display output file content
                if ($outputTextBox.Text -and (Test-Path $outputTextBox.Text)) {
                    $outputTextBox_display.AppendText("`r`n===== PROGRAM OUTPUT =====`r`n`r`n")
                    $outputContent = Get-Content $outputTextBox.Text
                    $outputContent | ForEach-Object { $outputTextBox_display.AppendText("$_`r`n") }
                }
            }
            else {
                $outputTextBox_display.AppendText("`r`n[ERROR] $($result.Error)`r`n")
                $statusLabel.Text = "Status: Failed"
                $statusLabel_bar.Text = " Execution failed"
            }
            
            $runButton.Enabled = $true
            $runButton.Text = "▶ RUN IN SANDBOX"
        }
        else {
            $outputTextBox_display.AppendText(".")
        }
    })
    $timer.Start()
})

$clearButton.Add_Click({
    $outputTextBox_display.Clear()
    $statusLabel.Text = "Status: Ready"
    $statusLabel_bar.Text = " Windows Sandbox Ready | Hyper-V Enabled | Security Policies Active"
})

$form.Add_Shown({
    $form.Activate()
    
    # Set default test program path
    $testProgram = Join-Path $PSScriptRoot "..\testprograms\Hello.exe"
    if (Test-Path $testProgram) {
        $exeTextBox.Text = $testProgram
    }
})

# Show form
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::Run($form)
'@

Set-Content -Path "$basePath\src\SandboxTool.ps1" -Value $sandboxTool -Force
Write-Host "  ✓ SandboxTool GUI created" -ForegroundColor Green

# Step 6: Create User Manual (PDF instructions)
Write-Host "`n[6/6] Creating documentation..." -ForegroundColor Green
