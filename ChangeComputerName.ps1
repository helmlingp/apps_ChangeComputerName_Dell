<#
  File: ChangeComputerName.ps1
  Author: helmlingp@vmware.com
  Modified: 7 February 2020

  # Set CUSTOMER Computer Naming Standards
    # For Desktops/Workstations, use PC-06 + $DellAssetTag
    # For Laptops/Notebooks, use LT-05 + $DellAssetTag
    # Set as per defined standard
    # How this works:
      # >> Two variables - $ComputerModel and $DellAssetTag data from WMI Query and Dell CCTK.
      # >> Then create two IF conditions depending on the computer model (in this case "LT-" for laptop or "PC-" for workstation).
      # >> In each if condition, combine LP or DT with a dash followed by $DellAssetTag (e.g. LP5-XXXXX).
#>
#==========================Header=============================#

$current_path = $PSScriptRoot;
if($PSScriptRoot -eq ""){
    $current_path = "C:\Temp";
}

# Get device Model and DellAssegTag from Dell Command Suite.
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

# Add / change prefix based on computer model
# Dell Workstations
if ($ComputerModel -match "Optiplex") {
    $Computername = "PC-" + $DellAssetTag
}
# Dell Laptops
if (($ComputerModel -match "Latitude") -OR ($ComputerModel -match "XPS")) {
    $Computername = "LT-" + $DellAssetTag
}

# Rename computername and restart but only if the AssetTag is populated
if (![string]::IsNullOrEmpty($DellAssetTag)){
  #write-host "New ComputerName is $Computername"
  Rename-Computer –newname $Computername
  
  Restart-Computer -force
}
