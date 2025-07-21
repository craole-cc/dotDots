
#region Environment Setup
function Global:Set-Env {
  param(
    [ValidateSet('variable', 'alias')]
    [string]$Type = 'variable',

    [switch]$Alias,
    [switch]$Variable,

    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [string]$Target,

    [alias('level', 'verbosity')]
    [string]$Tag = 'Error',

    [ValidateSet('Process', 'User', 'Machine', 'Global', 'Local', 'Script')]
    [string]$Scope
  )

  if ($Alias) {
    $Type = 'alias'
  }
  if ($Variable) {
    $Type = 'variable'
  }

  switch ($Type.ToLower()) {
    'variable' {
      #~@ Define allowed scopes for 'variable' type
      $allowedEnvScopes = @('Process', 'User', 'Machine')

      #~@ Set default scope if not provided
      if (-not $Scope) { $Scope = 'Process' }

      #~@ Validate that the provided/default scope is valid for 'variable'
      if ($Scope -notin $allowedEnvScopes) {
        throw [System.Management.Automation.ValidationMetadataException]::new(
          "Invalid scope '$Scope' for type 'variable'. Allowed values: $($allowedEnvScopes -join ', ')."
        )
      }

      #~@ Apply environment variable using provided or default scope
      [Environment]::SetEnvironmentVariable($Name, $Target, $Scope)

      #~@ Write debug message
      if ($Scope -eq 'Process') {
        Write-Pretty -Tag $Tag -DebugEnv "$Name" $Target
      }
      else {
        Write-Pretty -Tag $Tag -Delimiter "`n    "`
          "  Type | $Type" `
          "  Name | $Name" `
          " Scope | $Scope" `
          "Target | $Target" `

      }
    }
    'alias' {
      #~@ Define allowed scopes for 'alias' type
      $allowedAliasScopes = @('Global', 'Local', 'Script')

      #~@ Set default scope if not provided
      if (-not $Scope) { $Scope = 'Global' }

      #~@ Validate that the provided/default scope is valid for 'alias'
      if ($Scope -notin $allowedAliasScopes) {
        throw [System.Management.Automation.ValidationMetadataException]::new(
          "Invalid scope '$Scope' for type 'alias'. Allowed values: $($allowedAliasScopes -join ', ')."
        )
      }

      #~@ Set alias with correct scope
      Set-Alias -Name $Name -Value $Target -Scope $Scope -Force

      #~@ Write debug message
      Write-Pretty -Tag $Tag -Delimiter "`n    "`
        "  Type | $Type" `
        "  Name | $Name" `
        " Scope | $Scope" `
        "Target | $Target" `

    }
  }
}
#endregion
