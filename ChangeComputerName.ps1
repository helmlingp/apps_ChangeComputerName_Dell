<# 
  .SYNOPSIS
    This script renames a computer with the Serial Number of the device
  .DESCRIPTION
    Run on the local Win10+ device, Renames the computer to Serial Number derived from Win32_bios WMI Object.
    Adjust $Computername variable to suit your needs, such as adding a prefix.
    For Win10 2004 or newer devices joined to Active Directory Domain Services, domain credentials with permissions to 
    rename the computer object are required. Use the -Creds parameter to provide this credential.
    
    Includes an example, block commented out, describing using Dell CCTK to derive the device asset tag and prefixing the 
    computername based on the device ComputerSystem.Model.
  .EXAMPLE
    .\changecomputername.ps1 -Creds BASE64Creds -Restart
  .PARAMETER Creds
    Base64 Encoded DOMAIN Username + ":" + Password
    For example a user:P@ssw0rd is encoded to dXNlcjpQQHNzdzByZA==
    Use an online encoding site such as https://coderstoolbox.net/string/#!encoding=base64&action=encode&charset=utf_8 to encode
  .PARAMETER Restart
    If present, this parameter will send the "Restart-Computer" command
  .NOTES 
    Created:   	    February, 2020
    Updated:        February, 2022
    Created by:	    Phil Helmling, @philhelmling
    Organization:   VMware, Inc.
    Filename:       changecomputername.ps1
    GitHub:         https://github.com/helmlingp/apps_ChangeComputerName_Dell
#>
param (
    [Parameter(Mandatory=$false)]
    [string]$Creds,
    [Parameter(Mandatory=$false)]
    [switch]$Restart
)

$current_path = $PSScriptRoot;
if($PSScriptRoot -eq ""){
    $current_path = ".";
}

#Adjust the below to suit your needs
$ComputerName = (Get-WmiObject win32_bios | select Serialnumber).serialnumber
#Example using Dell CCTK to derive the device Asset Number and apply a prefix based on device type
<# # Get device Model and DellAssegTag from Dell Command Suite.
$ComputerModel = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object Model).Model
$SMBiosAssetTag = (Get-WmiObject  Win32_SystemEnclosure).SMBiosAssetTag

# Get Dell AssetTag attribute
# Credit - https://www.scconfigmgr.com/2018/07/23/dell-command-configure-toolkit-dynamic-wmi-acpi-legacy-detection/
# First determine if Dell Command Configure Toolkit (CCTK) will run. Requires ACPI BIOS. Can utilise the older version if needed and leverage versioninfo
#$CCTKVersion = (Get-ItemProperty $current_path\CCTK\cctk.exe | select -ExpandProperty VersionInfo).ProductVersion
#Write-host "Running Dell CCTK version $CCTKVersion on host system"
$CCTKExitCode = (Start-Process $current_path\CCTK\cctk.exe -Wait -PassThru).ExitCode
#Write-Host "Dell CCTK exit code is $CCTKExitCode"
if (($CCTKExitCode -eq "141") -or ($CCTKExitCode -eq "140")) {
  #Write-host "Non WMI-ACPI BIOS detected. Setting CCTK legacy mode"
  exit
} else {
  #Write-host "WMI-ACPI BIOS detected" 
  $DellAssetTag = Invoke-Command -scriptblock {cmd /c "$current_path\CCTK\cctk.exe" '--asset'}
  if($DellAssetTag.StartsWith("Asset=")){
    $DellAssetTag = $DellAssetTag.SubString($DellAssetTag.LastIndexOf("=")+1)
  } else {
    #write-host "Can't change computername as asset tag not set. Using sysprep computername"
    exit
  }
}
if (![string]::IsNullOrEmpty($DellAssetTag)){
  # Add / change prefix based on computer model
  if ($ComputerModel -match "Optiplex") {
      $Computername = "PC-" + $DellAssetTag
  }
  # Dell Laptops
  if (($ComputerModel -match "Latitude") -OR ($ComputerModel -match "XPS")) {
      $Computername = "LT-" + $DellAssetTag
  }
}
 #>

if($Creds){
  $unencoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Creds))
  $Username = $unencoded.substring(0,$unencoded.IndexOf(":"))
  $Password = $unencoded.substring($unencoded.IndexOf(":")+1)
  $sPassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
  $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $sPassword

  #Rename Computer using domain credentials provided. Required for Win10 2004 and above
  Rename-Computer -NewName $ComputerName -DomainCredential $Credential -Force
  if($Restart.IsPresent){
    Restart-Computer -force
  }
} else {
  Rename-Computer -NewName $ComputerName -Force
  if($Restart.IsPresent){
    Restart-Computer -force
  }
}

