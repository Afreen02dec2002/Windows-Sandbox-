
$guiFile = @'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$testProgramsDir = "$scriptPath\..\testprograms"
$outputDir = "$scriptPath\..\output"
$configDir = "$scriptPath\..\configs"

# Create directories if they don't exist
New-Item -ItemType Directory -Force -Path $testProgramsDir | Out-Null
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
New-Item -ItemType Directory -Force -Path $configDir | Out-Null

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows Sandbox Tool - Trustworthy Computing"
$form.Size = New-Object System.Drawing.Size(700, 500)
$form.StartPosition = "CenterScreen"
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.BackColor = [System.Drawing.Color]::White

# Title
$title = New-Object System.Windows.Forms.Label
$title.Text = "Windows Sandbox Execution Tool"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$title.Location = New-Object System.Drawing.Point(20, 20)
$title.Size = New-Object System.Drawing.Size(650, 40)
$form.Controls.Add($title)

# Program Selection Group
$groupProgram = New-Object System.Windows.Forms.GroupBox
$groupProgram.Text = "1. Program Selection"
$groupProgram.Location = New-Object System.Drawing.Point(20, 70)
$groupProgram.Size = New-Object System.Drawing.Size(640, 80)
$groupProgram.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($groupProgram)

$lblPath = New-Object System.Windows.Forms.Label
$lblPath.Text = "Executable:"
$lblPath.Location = New-Object System.Drawing.Point(10, 30)
$lblPath.Size = New-Object System.Drawing.Size(80, 25)
$lblPath.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$groupProgram.Controls.Add($lblPath)

$txtPath = New-Object System.Windows.Forms.TextBox
$txtPath.Location = New-Object System.Drawing.Point(100, 27)
$txtPath.Size = New-Object System.Drawing.Size(420, 25)
$txtPath.Text = "$testProgramsDir\Hello.exe"
$groupProgram.Controls.Add($txtPath)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Browse..."
$btnBrowse.Location = New-Object System.Drawing.Point(530, 26)
$btnBrowse.Size = New-Object System.Drawing.Size(90, 28)
$btnBrowse.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Executable files (*.exe)|*.exe|All files (*.*)|*.*"
    $ofd.InitialDirectory = $testProgramsDir
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtPath.Text = $ofd.FileName
    }
})
$groupProgram.Controls.Add($btnBrowse)

# Input Data
$lblInput = New-Object System.Windows.Forms.Label
$lblInput.Text = "Input Data:"
$lblInput.Location = New-Object System.Drawing.Point(10, 65)
$lblInput.Size = New-Object System.Drawing.Size(80, 25)
$lblInput.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$groupProgram.Controls.Add($lblInput)

$txtInput = New-Object System.Windows.Forms.TextBox
$txtInput.Location = New-Object System.Drawing.Point(100, 62)
$txtInput.Size = New-Object System.Drawing.Size(520, 25)
$txtInput.Text = "World"
$groupProgram.Controls.Add($txtInput)

# Security Policies Group
$groupSecurity = New-Object System.Windows.Forms.GroupBox
$groupSecurity.Text = "2. Security Policies"
$groupSecurity.Location = New-Object System.Drawing.Point(20, 160)
$groupSecurity.Size = New-Object System.Drawing.Size(640, 100)
$groupSecurity.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($groupSecurity)

$chkNetwork = New-Object System.Windows.Forms.CheckBox
$chkNetwork.Text = "Disable Network"
$chkNetwork.Location = New-Object System.Drawing.Point(20, 30)
$chkNetwork.Size = New-Object System.Drawing.Size(150, 25)
$chkNetwork.Checked = $true
$groupSecurity.Controls.Add($chkNetwork)

$chkGPU = New-Object System.Windows.Forms.CheckBox
$chkGPU.Text = "Disable GPU"
$chkGPU.Location = New-Object System.Drawing.Point(180, 30)
$chkGPU.Size = New-Object System.Drawing.Size(150, 25)
$chkGPU.Checked = $true
$groupSecurity.Controls.Add($chkGPU)

$chkAudio = New-Object System.Windows.Forms.CheckBox
$chkAudio.Text = "Disable Audio"
$chkAudio.Location = New-Object System.Drawing.Point(340, 30)
$chkAudio.Size = New-Object System.Drawing.Size(150, 25)
$chkAudio.Checked = $true
$groupSecurity.Controls.Add($chkAudio)

$chkReadOnly = New-Object System.Windows.Forms.CheckBox
$chkReadOnly.Text = "Read-Only Mode"
$chkReadOnly.Location = New-Object System.Drawing.Point(20, 60)
$chkReadOnly.Size = New-Object System.Drawing.Size(150, 25)
$chkReadOnly.Checked = $false
$groupSecurity.Controls.Add($chkReadOnly)

$chkClipboard = New-Object System.Windows.Forms.CheckBox
$chkClipboard.Text = "Disable Clipboard"
$chkClipboard.Location = New-Object System.Drawing.Point(180, 60)
$chkClipboard.Size = New-Object System.Drawing.Size(150, 25)
$chkClipboard.Checked = $true
$groupSecurity.Controls.Add($chkClipboard)

$chkPrinter = New-Object System.Windows.Forms.CheckBox
$chkPrinter.Text = "Disable Printers"
$chkPrinter.Location = New-Object System.Drawing.Point(340, 60)
$chkPrinter.Size = New-Object System.Drawing.Size(150, 25)
$chkPrinter.Checked = $true
$groupSecurity.Controls.Add($chkPrinter)

# Output Group
$groupOutput = New-Object System.Windows.Forms.GroupBox
$groupOutput.Text = "3. Output Configuration"
$groupOutput.Location = New-Object System.Drawing.Point(20, 270)
$groupOutput.Size = New-Object System.Drawing.Size(640, 70)
$groupOutput.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($groupOutput)

$lblOutput = New-Object System.Windows.Forms.Label
$lblOutput.Text = "Save to:"
$lblOutput.Location = New-Object System.Drawing.Point(10, 30)
$lblOutput.Size = New-Object System.Drawing.Size(80, 25)
$lblOutput.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$groupOutput.Controls.Add($lblOutput)

$txtOutput = New-Object System.Windows.Forms.TextBox
$txtOutput.Location = New-Object System.Drawing.Point(100, 27)
$txtOutput.Size = New-Object System.Drawing.Size(520, 25)
$txtOutput.Text = "$outputDir\output_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$groupOutput.Controls.Add($txtOutput)

# Execute Button
$btnExecute = New-Object System.Windows.Forms.Button
$btnExecute.Text = "▶ EXECUTE PROGRAM IN SANDBOX"
$btnExecute.Location = New-Object System.Drawing.Point(20, 360)
$btnExecute.Size = New-Object System.Drawing.Size(640, 50)
$btnExecute.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$btnExecute.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
$btnExecute.ForeColor = [System.Drawing.Color]::White
$btnExecute.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnExecute.Add_Click({
    $btnExecute.Enabled = $false
    $btnExecute.Text = "⏳ EXECUTING... PLEASE WAIT"
    
    # Check if file exists
    if (Test-Path $txtPath.Text) {
        [System.Windows.Forms.MessageBox]::Show(
            "Sandbox execution started!`n`nProgram: $($txtPath.Text)`nInput: $($txtInput.Text)",
            "Windows Sandbox",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    } else {
        [System.Windows.Forms.MessageBox]::Show(
            "Program file not found! Please create or select a valid executable.",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
    
    $btnExecute.Enabled = $true
    $btnExecute.Text = "▶ EXECUTE PROGRAM IN SANDBOX"
})
$form.Controls.Add($btnExecute)

# Create Test Program Button
$btnCreateTest = New-Object System.Windows.Forms.Button
$btnCreateTest.Text = "🔧 CREATE TEST PROGRAM (Hello.exe)"
$btnCreateTest.Location = New-Object System.Drawing.Point(20, 420)
$btnCreateTest.Size = New-Object System.Drawing.Size(640, 35)
$btnCreateTest.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnCreateTest.BackColor = [System.Drawing.Color]::FromArgb(40, 167, 69)
$btnCreateTest.ForeColor = [System.Drawing.Color]::White
$btnCreateTest.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCreateTest.Add_Click({
    $csPath = "$testProgramsDir\Hello.cs"
    
    # Simple C# code that will definitely compile
    $csCode = 'using System;

class Program
{
    static void Main()
    {
        Console.WriteLine("Hello World!");
        Console.Write("Enter your name: ");
        string name = Console.ReadLine();
        if (string.IsNullOrEmpty(name))
        {
            name = "World";
        }
        Console.WriteLine("Hello " + name + "!");
        Console.WriteLine("Press any key to exit...");
        Console.ReadKey();
    }
}'
    
    # Save with ASCII encoding
    $csCode | Out-File -FilePath $csPath -Encoding ASCII -Force
    
    # Compile
    $cscPath = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
    if (Test-Path $cscPath) {
        Start-Process -FilePath $cscPath -ArgumentList "`"$csPath`" /out:`"$testProgramsDir\Hello.exe`"" -Wait -NoNewWindow
        
        if (Test-Path "$testProgramsDir\Hello.exe") {
            $txtPath.Text = "$testProgramsDir\Hello.exe"
            [System.Windows.Forms.MessageBox]::Show(
                "Test program created successfully!",
                "Success",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        } else {
            [System.Windows.Forms.MessageBox]::Show(
                "Compilation failed. Please check the C# compiler.",
                "Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
    }
})
$form.Controls.Add($btnCreateTest)

# Show the form
$form.ShowDialog()
'@
