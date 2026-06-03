<#
.SYNOPSIS
    Configures Windows Server 2022 as a Domain Controller, creates GPOs, batch users, and scheduled tasks.
    Must be executed during Windows Server startup (userdata).
#>

$ErrorActionPreference = 'Stop'
$domainName = 'lab.local'
$netbiosName = 'LAB'
$safeModePass = ConvertTo-SecureString 'Admin@2026' -AsPlainText -Force
$logPath = 'C:\Logs\configure-ad.log'

# Number of lab users to create (configurable via environment variable)
$userCount = [int]($env:USER_COUNT -or 10)

Start-Transcript -Path $logPath -Append

try {
    # Check if AD module is available
    $adModuleAvailable = Get-Module -ListAvailable -Name ActiveDirectory -ErrorAction SilentlyContinue
    $adServiceInstalled = Get-WindowsFeature -Name AD-Domain-Services -ErrorAction SilentlyContinue | Where-Object { $_.Installed }

    if (-not $adServiceInstalled) {
        Write-Host "=== Installing AD Domain Services ===" -ForegroundColor Green
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -Restart:$false | Out-Null

        Write-Host "=== Promoting server to Domain Controller ===" -ForegroundColor Green
        Import-Module ADDSDeployment
        Install-ADDSForest `
            -CreateDnsDelegation:$false `
            -DatabasePath 'C:\Windows\NTDS' `
            -DomainMode 'WinThreshold' `
            -DomainName $domainName `
            -DomainNetbiosName $netbiosName `
            -ForestMode 'WinThreshold' `
            -InstallDns:$true `
            -LogPath 'C:\Windows\NTDS' `
            -SysvolPath 'C:\Windows\SYSVOL' `
            -SafeModeAdministratorPassword $safeModePass `
            -Force:$true

        Write-Host "=== Install-ADDSForest will reboot the server automatically ===" -ForegroundColor Yellow
        return
    }

    # Only run post-reboot configuration if AD module is available
    if (-not $adModuleAvailable) {
        Write-Host "=== AD module not yet available, importing... ===" -ForegroundColor Yellow
        Import-Module ActiveDirectory -ErrorAction Stop
    }

    Write-Host "=== Validating domain state ===" -ForegroundColor Green
    try {
        $domain = Get-ADDomain -ErrorAction Stop
    }
    catch {
        Write-Host "=== Domain not yet available (reboot may not have occurred). Rebooting... ===" -ForegroundColor Yellow
        Restart-Computer -Force
        return
    }

    Write-Host "=== Configuring Domain Controller and policies ===" -ForegroundColor Green

    # Ensure AD and GPO modules are installed
    $gpmcInstalled = Get-WindowsFeature -Name GPMC -ErrorAction SilentlyContinue | Where-Object { $_.Installed }
    if (-not $gpmcInstalled) {
        Write-Host "=== Installing GPMC (Group Policy Management Console) ===" -ForegroundColor Green
        Install-WindowsFeature -Name GPMC -IncludeManagementTools | Out-Null
    }

    Import-Module ActiveDirectory
    Import-Module GroupPolicy

    $domainDn = $domain.DistinguishedName

    # Create and link GPO: Launch Notepad on Logon
    $gpoName = 'Launch Notepad on Logon'
    $gpo = Get-GPO -Name $gpoName -ErrorAction SilentlyContinue
    if (-not $gpo) {
        $gpo = New-GPO -Name $gpoName -Comment 'Launch Notepad automatically for domain users at logon'
    }

    # Check if GPO is already linked
    $linkExists = $false
    try {
        $links = Get-GPLink -Guid $gpo.Id -ErrorAction SilentlyContinue
        if ($links) { $linkExists = $true }
    }
    catch {
        try {
            $domainObj = Get-ADDomain
            $allLinks = $domainObj.LinkedGroupPolicyObjects
            if ($allLinks -match $gpo.Id.Guid) { $linkExists = $true }
        }
        catch {}
    }

    if (-not $linkExists) {
        New-GPLink -Name $gpoName -Target $domainDn -LinkEnabled Yes | Out-Null
    }

    Set-GPRegistryValue -Name $gpoName -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Run' -ValueName 'LaunchNotepad' -Type String -Value 'C:\Windows\System32\notepad.exe' | Out-Null

    # Create and link GPO: Restrict C Drive Access
    $gpoUpdate = 'Restrict C Drive Access'
    $driveGpo = Get-GPO -Name $gpoUpdate -ErrorAction SilentlyContinue
    if (-not $driveGpo) {
        $driveGpo = New-GPO -Name $gpoUpdate -Comment 'Restrict non-admin users from browsing drive C:'
    }

    $linkExists2 = $false
    try {
        $links2 = Get-GPLink -Guid $driveGpo.Id -ErrorAction SilentlyContinue
        if ($links2) { $linkExists2 = $true }
    }
    catch {}

    if (-not $linkExists2) {
        New-GPLink -Name $gpoUpdate -Target $domainDn -LinkEnabled Yes | Out-Null
    }

    Set-GPRegistryValue -Name $gpoUpdate -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -ValueName 'NoViewOnDrive' -Type DWord -Value 4 | Out-Null

    # Create Lab Organizational Unit
    $ouName = 'LabUsers'
    $labOu = Get-ADOrganizationalUnit -Filter "Name -eq '$ouName'" -ErrorAction SilentlyContinue
    if (-not $labOu) {
        New-ADOrganizationalUnit -Name $ouName -Path $domainDn -ProtectedFromAccidentalDeletion $false | Out-Null
        Write-Host "=== OU created: $ouName ===" -ForegroundColor Green
    }

    # Create batch lab users with ChangePasswordAtLogon = $true
    $ouPath = "OU=$ouName,$domainDn"
    $plainPassword = "P@ssw0rd123!"

    Write-Host "=== Creating $userCount lab users with forced password change on first logon ===" -ForegroundColor Green

    for ($i = 1; $i -le $userCount; $i++) {
        $username = "user$i"
        $adUser = Get-ADUser -Filter "SamAccountName -eq '$username'" -ErrorAction SilentlyContinue
        if (-not $adUser) {
            $securePassword = ConvertTo-SecureString $plainPassword -AsPlainText -Force
            New-ADUser `
                -Name "User $i" `
                -SamAccountName $username `
                -UserPrincipalName "$username@$domainName" `
                -Path $ouPath `
                -AccountPassword $securePassword `
                -Enabled $true `
                -ChangePasswordAtLogon $true `
                -PasswordNeverExpires $false | Out-Null

            Write-Host "    [+] Created: $username@$domainName (password change required on first logon)" -ForegroundColor Yellow
        } else {
            Write-Host "    [-] Skipped: $username (already exists)" -ForegroundColor Gray
        }
    }

    # Create scheduled task: Daily Reboot at 03:00 AM
    $taskName = 'DailyReboot'
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if (-not $existingTask) {
        $trigger = New-ScheduledTaskTrigger -Daily -At 03:00
        $action = New-ScheduledTaskAction -Execute 'C:\Windows\System32\shutdown.exe' -Argument '/r /f /t 0'
        Register-ScheduledTask `
            -TaskName $taskName `
            -TaskPath '\' `
            -Trigger $trigger `
            -Action $action `
            -RunLevel Highest `
            -Force | Out-Null
        Write-Host "=== Scheduled task '$taskName' created (daily reboot at 03:00) ===" -ForegroundColor Green
    }

    Write-Host "=== Applying GPOs ===" -ForegroundColor Green
    gpupdate /force /target:computer | Out-Null
    gpupdate /force /target:user | Out-Null

    Write-Host "=== Domain configuration completed ===" -ForegroundColor Green

    # Grant RDP access to domain users via local policy
    Write-Host "=== Granting RDP permissions to domain users ===" -ForegroundColor Green
    try {
        Add-ADGroupMember -Identity "Remote Desktop Users" -Members "Domain Users" -ErrorAction SilentlyContinue
    } catch {
        Write-Host "    [!] Could not add Domain Users to Remote Desktop Users group: $_" -ForegroundColor Yellow
    }

    # Add Remote Desktop Users SID to the local RDP policy
    $secpolFile = "C:\Logs\secpol.cfg"
    secedit /export /cfg $secpolFile | Out-Null
    $secpol = Get-Content $secpolFile
    $rdpSid = '*S-1-5-32-555'
    $adminSid = '*S-1-5-32-544'

    $currentLine = ($secpol | Select-String "SeRemoteInteractiveLogonRight").Line
    if ($currentLine -notmatch [regex]::Escape($rdpSid)) {
        $newLine = "SeRemoteInteractiveLogonRight = $adminSid,$rdpSid"
        $secpol = $secpol -replace 'SeRemoteInteractiveLogonRight = .*', $newLine
        $secpol | Set-Content $secpolFile
        secedit /configure /db secedit.sdb /cfg $secpolFile | Out-Null
        Write-Host "=== RDP permission granted for domain users ===" -ForegroundColor Green
    }

    # Generate users report file
    $reportPath = "C:\Logs\lab-users.csv"
    Get-ADUser -Filter * -SearchBase $ouPath -Properties UserPrincipalName, PasswordLastSet, PasswordExpired |
        Select-Object Name, SamAccountName, UserPrincipalName, Enabled, PasswordExpired, PasswordLastSet |
        Export-Csv -Path $reportPath -NoTypeInformation
    Write-Host "=== Users report generated: $reportPath ===" -ForegroundColor Green

    # Remove RunOnce entry so it doesn't run again
    $runOncePath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
    Remove-ItemProperty -Path $runOncePath -Name 'ConfigureAD' -ErrorAction SilentlyContinue
    Write-Host "=== RunOnce ConfigureAD removed ===" -ForegroundColor Green

    Write-Host "=== Configuration completed successfully ===" -ForegroundColor Green
}
catch {
    Write-Host "=== ERROR: $_ ===" -ForegroundColor Red
    $_ | Out-File -FilePath 'C:\Logs\configure-ad-error.log' -Append
}
finally {
    Stop-Transcript
}
