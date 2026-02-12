$helperModule = @'
function Test-WindowsSandboxEnabled {
    return (Test-Path "$env:windir\System32\WindowsSandbox.exe")
}

function Test-ValidExecutable {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $false }
    return ([System.IO.Path]::GetExtension($Path) -eq ".exe")
}

function New-SandboxConfiguration {
    param(
        [string]$ConfigPath,
        [string]$HostProgramPath,
        [string]$InputData = "",
        [switch]$NoNetwork,
        [switch]$ReadOnly,
        [switch]$NoGPU,
        [switch]$NoAudio,
        [switch]$NoPrinter,
        [switch]$NoClipboard
    )
    
    $configDir = Split-Path -Parent $ConfigPath
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Force -Path $configDir | Out-Null
    }
    
    $programName = Split-Path -Leaf $HostProgramPath
    $hostFolder = Split-Path -Parent $HostProgramPath
    
    $configContent = @"
<Configuration>
    <Networking>$(if ($NoNetwork) { 'Disable' } else { 'Default' })</Networking>
    <VGpu>$(if ($NoGPU) { 'Disable' } else { 'Default' })</VGpu>
    <AudioInput>$(if ($NoAudio) { 'Disable' } else { 'Default' })</AudioInput>
    <PrinterRedirection>$(if ($NoPrinter) { 'Disable' } else { 'Default' })</PrinterRedirection>
    <ClipboardRedirection>$(if ($NoClipboard) { 'Disable' } else { 'Default' })</ClipboardRedirection>
    <MappedFolders>
        <MappedFolder>
            <HostFolder>$hostFolder</HostFolder>
            <SandboxFolder>C:\sandbox</SandboxFolder>
            <ReadOnly>$(if ($ReadOnly) { 'true' } else { 'false' })</ReadOnly>
        </MappedFolder>
    </MappedFolders>
    <LogonCommand>
        <Command>powershell.exe -Command "& { Set-Location C:\sandbox; & '.\$programName'; Start-Sleep -Seconds 2; }"</Command>
    </LogonCommand>
</Configuration>
"@
    
    $configContent | Out-File -FilePath $ConfigPath -Encoding ASCII -Force
    return $ConfigPath
}

function Start-WindowsSandbox {
    param([string]$ConfigPath)
    return Start-Process "$env:windir\System32\WindowsSandbox.exe" -ArgumentList "`"$ConfigPath`"" -PassThru
}

function Get-SandboxOutput {
    param([string]$HostProgramPath, [string]$SaveToFile)
    
    $hostFolder = Split-Path -Parent $HostProgramPath
    $outputPath = Join-Path $hostFolder "output.txt"
    
    $output = ""
    for ($i = 0; $i -lt 10; $i++) {
        if (Test-Path $outputPath) {
            $output = Get-Content $outputPath -Raw -ErrorAction SilentlyContinue
            break
        }
        Start-Sleep -Milliseconds 500
    }
    
    if ($SaveToFile -and $output) {
        $output | Out-File -FilePath $SaveToFile -Encoding ASCII -Force
    }
    return $output
}

Export-ModuleMember -Function Test-WindowsSandboxEnabled, Test-ValidExecutable, 
                    New-SandboxConfiguration, Start-WindowsSandbox, Get-SandboxOutput
'@
