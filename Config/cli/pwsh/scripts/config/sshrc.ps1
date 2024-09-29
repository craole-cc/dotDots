# ___________________________________________________________ RC <|

$rc = $PSCommandPath
function editRC { code $rc }

# _____________________________________________________ Resources<|

$resources=$PSScriptRoot+"\resources\environment\*ssh*.ps1"
Get-ChildItem $resources | ForEach-Object{. $_ }

# _____________________________________________________ Functions<|

vps # Contabo Instance