
#region Functions
function Global:Invoke-Mise {
  <#
  .SYNOPSIS
    Invokes the mise command with the provided arguments.
  .DESCRIPTION
    This function invokes the mise command with the provided arguments.
  .PARAMETER Arguments
    Optional arguments to pass to the mise command.
    #>
  param (
    [Parameter(ValueFromRemainingArguments = $true, Position = 0)]
    [string[]]$Arguments = @()
  )

  & mise @Arguments
}
function Initialize-Mise {
  <#
  .SYNOPSIS
    Initializes the mise environment for PowerShell.
  .DESCRIPTION
    This function checks if the mise command is available and activates it. If not, it attempts to install mise using scoop or winget.
  #>
  [CmdletBinding()]
  param()

  if (-not (Get-Command -Name 'mise' -ErrorAction SilentlyContinue)) {
    if (-not (Install-Mise)) {
      Write-Pretty -Tag 'Error' 'Mise installation failed. Cannot initialize.'
      return
    }
  }

  try {
    mise activate pwsh | Out-String | Invoke-Expression
    Write-Pretty -Tag 'Info' -NoNewLine 'Successfully activated mise.'
  }
  catch {
    Write-Pretty -Tag 'Error' `
      'Activation failed' `
      "Details: $($_.Exception.Message)"
  }
}
function Global:Install-Mise {
  <#
  .SYNOPSIS
    Installs mise if it is not already present.
  .DESCRIPTION
    Checks for mise and installs it using scoop or winget if not found.
    It then runs `mise install` to set up configured tools.
  .OUTPUTS
    [bool] Returns $true on success, $false on failure.
  #>
  [CmdletBinding()]
  param()

  if (Get-Command -Name 'mise' -ErrorAction SilentlyContinue) {
    Write-Pretty -Tag 'Trace' 'mise is already installed.'
    return $true
  }

  Write-Pretty -Tag 'Warning' 'mise is not installed. Attempting to install...'
  if (Get-Command -Name 'scoop' -ErrorAction SilentlyContinue) {
    Write-Pretty -Tag 'Trace' 'Installing mise with scoop...'
    scoop install mise
  }
  elseif (Get-Command -Name 'winget' -ErrorAction SilentlyContinue) {
    Write-Pretty -Tag 'Trace' 'Installing mise with winget...'
    winget install jdx.mise
  }
  else {
    Write-Pretty -Tag 'Error' 'Neither scoop nor winget is available. Please install mise manually.'
    return $false
  }

  # Verify installation
  if (-not (Get-Command -Name 'mise' -ErrorAction SilentlyContinue)) {
    Write-Pretty -Tag 'Error' 'mise command is still not available after installation attempt.'
    return $false
  }

  # Install dependencies defined in mise config
  Write-Pretty -Tag 'Info' 'Running `mise install` to set up tools...'
  mise install --quiet

  if ($LASTEXITCODE -eq 0) {
    Write-Pretty -Tag 'Success' 'mise has been successfully installed and its tools are set up.'
    return $true
  }
}
function Global:Push-via-mise {
  mise push

  if ($LASTEXITCODE -eq 0) {
    Write-Pretty -Tag 'Success' 'Pushed changes via mise successfully.'
    return $true
  }
  else {
    Write-Pretty -Tag 'Error' 'Failed to push changes via mise.'
    return $false
  }
}
#endregion

#region Aliases
Set-Alias -Name m -Value Invoke-Mise -Scope Global -Force
Set-Alias -Name push -Value Push-via-mise -Scope Global -Force
#endregion

Initialize-Mise
