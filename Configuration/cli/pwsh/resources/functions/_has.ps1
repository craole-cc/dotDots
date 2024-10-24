$command = $args
Function Has {
  Param ($command)
  $oldPreference = $ErrorActionPreference
  $ErrorActionPreference = ‘stop’
  try {if(Get-Command $command){RETURN $true}}
  Catch {Write-Host “$command does not exist”; RETURN $false}
  Finally {$ErrorActionPreference=$oldPreference}
}