#requires -version 5.1

#test profile script performance

<#
C:\scripts\Test-ProfilePerf.ps1
C:\scripts\Test-ProfilePerf.ps1 -outvariable p | measure-object -Property TimeMS -sum
$p

#>

[cmdletbinding()]
Param()

#this is the scriptblock of commands to run in a new Powershell/pwsh session
$sb = {
    $profiles = [ordered]@{
        AllUsersAllHosts       = $profile.AllUsersAllHosts
        AllUsersCurrentHost    = $profile.AllUsersCurrentHost
        CurrentUserAllHosts    = $profile.CurrentUserAllHosts
        CurrentUserCurrentHost = $profile.CurrentUserCurrentHost
    }

    #only need to get these values once
    $psver = $PSVersionTable.PSVersion
    $computer = [System.Environment]::MachineName
    $user = "$([System.Environment]::UserDomainName)\$([system.Environment]::userName)"

    foreach ($prof in $profiles.GetEnumerator()) {
        If (Test-Path $prof.value) {
            # Write-Host "Measuring script for $($prof.key)" -ForegroundColor cyan
            $m = Measure-Command { . $prof.value }

            #create a result
            [pscustomobject]@{
                Computername = $computer
                Username     = $user
                PSVersion    = $psver
                Profile      = $prof.key
                Path         = $prof.value
                TimeMS       = $m.totalMilliseconds
            }
        } #if test path

    } #foreach profile
} #scriptblock

#use the detected PowerShell version
if ($PSEdition -eq 'Core') {
    #Windows uses pwsh.exe and non-Windows uses pwsh.
    $cmd = (Get-Command pwsh).source
    $result = &$cmd -nologo -noprofile -command $sb
}
else {
    $result = powershell.exe -nologo -noprofile -command $sb
}

#use $result as the output of this command
$result