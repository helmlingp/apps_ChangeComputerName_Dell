# apps_ChangeComputerName_Dell
Run on the local Win10+ device, Renames the computer to Serial Number derived from Win32_bios WMI Object.
Adjust $Computername variable to suit your needs, such as adding a prefix.
For Win10 2004 or newer devices joined to Active Directory Domain Services, domain credentials with permissions to 
rename the computer object are required. Use the -Creds parameter to provide this credential.

Includes an example, block commented out, describing using Dell CCTK to derive the device asset tag and prefixing the 
computername based on the device ComputerSystem.Model.

Example
.\changecomputername.ps1 -Creds BASE64Creds -Restart

Parameters
-Creds
Base64 Encoded DOMAIN Username + ":" + Password
For example a user:P@ssw0rd is encoded to dXNlcjpQQHNzdzByZA==
Use an online encoding site such as https://coderstoolbox.net/string/#!encoding=base64&action=encode&charset=utf_8 to encode

-Restart
If present, this parameter will send the "Restart-Computer" command
