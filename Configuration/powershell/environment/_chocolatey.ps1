# Chocolatey

# ____________________________________________________________________ Install<|

If (!(Test-Path 'C:\Program Files\git\usr\bin\ssh-keygen.exe'))
{
  Write-Host 'Installing latest git client using Chocolatey'
  If (!(Test-Path env:chocolateyinstall))
  {
    Write-Host "Chocolatey is not present, installing on demand."
    Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
  }
}

# ____________________________________________________________________ Profile<|

  $chocoRC = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
  if (Test-Path("$chocoRC")) { Import-Module "$chocoRC" }

  # ___________________________________________________________________ Packages<|

    Set-Alias p clist
    Set-Alias pa cinst

    function cS {
      # |> Search
      choco list `
      --not-broken `
      --order-by-popularity `
      $args
    }

    function cSd # |> Search with details
    {
      choco list `
      --not-broken `
      --order-by-popularity `
      --detailed `
      $args
    }
    # function cS { choco search }
    function cLl { choco list --local $args }
    function cLg { choco list --local | grep \W*$args }
    function cin { choco upgrade $args }
    function cun { choco uninstall $args }
    function cfo { choco info $args }
    function cU { cup all }
    function cH { choco help }
    function ccl { choco-cleaner }