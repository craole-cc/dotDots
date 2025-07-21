$command = $args
function Has {
    param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = ‘stop’
    try { if (Get-Command $command) { return $true } }
    catch { Write-Host “$command does not exist”; return $false }
    finally { $ErrorActionPreference = $oldPreference }
}
