<#
.SYNOPSIS
  Setup and Install Rancher RKE2 in Windows Worker Nodes.
.DESCRIPTION
  Run the script to setup and install all Rancher RKE2 related needs.
.Parameter ServerIP
    Server IP of Primary server where rke2 is already installed and the worker will join.`
.Parameter Token
    Token of Primary server.`
.Parameter Version
    Version of rke2 to download from github.`
.Parameter Commit
    Commit of RKE2 to download from temporary cloud storage.
    If set, this forces Method=tar.
    * (for developer & QA use only)`
.EXAMPLE
  Usage:
    Invoke-WebRequest ((New-Object System.Net.WebClient).DownloadString('https://github.com/rancher/rke2/blob/master/setup-and-install.ps1'))
    ./setup-and-install.ps1
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $ServerIP,
    [Parameter()]
    [String]
    $Version,
    [Parameter()]
    [String]
    $Token,
    [Parameter()]
    [String]
    $Commit
)

function Write-InfoLog() {
    Write-Output "[INFO] $($args -join " ")"
}

function Write-WarnLog() {
    Write-Output "[WARN] $($args -join " ")"
}

function Write-DebugLog() {
    Write-Output "[DEBUG] $($args -join " ")"
}

# Set the version or commit based of cli
function Set-Version() {
    if ($Commit) {
        $Version = "commit $($Commit)"
    }
    elseif ($Version) {
        $Version = $Version
    }
    return $Version
}

function Enable-Features() {
    Enable-WindowsOptionalFeature -Online -FeatureName Containers -All
}

function Setup-Config(){
    Write-InfoLog "Creating rke2 directory..."
    New-Item -Type Directory c:/etc/rancher/rke2 -Force
    Write-InfoLog "Setting up rke2 config.yaml file..."
    Set-Content -Path c:/etc/rancher/rke2/config.yaml -Value "server: https://$($ServerIP):9345`ntoken: $Token`n"
    Get-Content -Path c:/etc/rancher/rke2/config.yaml
}

function Setup-EnvironmentVariables(){
    Write-InfoLog "Setting up environment vars..."
    [System.Environment]::SetEnvironmentVariable(
        "Path",[System.Environment]::GetEnvironmentVariable(
            "Path", [System.EnvironmentVariableTarget]::Machine) + ";c:\var\lib\rancher\rke2\bin;c:\usr\local\bin",
    [System.EnvironmentVariableTarget]::Machine)
}

function Install-rke2(){
    Write-InfoLog "Downloading install script..."
    Invoke-WebRequest -Uri https://raw.githubusercontent.com/rancher/rke2/master/install.ps1 -Outfile C:\Users\Administrator\install.ps1
    Write-InfoLog "Installing rke2 $Version..."
    Invoke-Expression -Command "C:\Users\Administrator\install.ps1 -Version $Version"
}

function Start-rke2(){
    Write-InfoLog "Adding rke2-agent service..."
    Invoke-Expression -Command "C:\usr\local\bin\rke2.exe agent service --add"
    Write-InfoLog "Starting rke2-agent service..."
    Start-Service rke2
}


Enable-Features
Setup-Config
Setup-EnvironmentVariables
Set-Version
Install-rke2
Start-rke2
