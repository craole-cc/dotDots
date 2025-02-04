$ENV:DOTS = "C:/CC/Dotfiles"
$ENV:PSDOTS = "C:/CC/Dotfiles/Config/cli/pwsh"
# Set-Location $Env:DOTS
# ___________________________________________________________ RC <|



# _________________________________________________________ PATH <|


$SCR = $PSCommandPath
$CWD = $PSScriptRoot
$scripts = $CWD + "\..\scripts"
# $cmderautostart = $CWD + "\cmder.log"
$resources = $CWD + "\..\resources"
$functions = $resources + "\functions\*.ps1"
$enVar = $resources + "\environment\*.ps1"

# Write-Output $CWD
# Write-Output $SCR
# Get-ChildItem $resources
# Get-ChildItem $enVar
# Get-Content $cmderautostart

$ENV:Path += ";$CWD"
$ENV:Path += ";$scripts"

#@_______________________________________________ Resources<|

Get-ChildItem $functions | ForEach-Object{. $_ }
Get-ChildItem $enVar | ForEach-Object{. $_ }

# _____________________________________________________ Defaults <|

function editRC { code $SCR }
Set-Alias code code-insiders
Set-Alias psh "$ENV:PSDOTS/config/psh.bat"

# __________________________________________________________ Exec<|

Import-Module -Name Terminal-Icons
Invoke-Expression (&starship init powershell)
$ENV:STARSHIP_CONFIG = "$DOTS/Utilities/config/starship/starship.toml"

Clear-Host
macchina