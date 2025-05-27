function Global:Get-Env {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0)]
    [string]$Name,

    [Parameter()]
    [string]$Default = $null,

    [Parameter()]
    [ValidateSet('Process', 'User', 'Machine', 'All')]
    [string]$Scope = 'Process'
  )

  if ([string]::IsNullOrEmpty($Name)) {
    # If no name specified, return all environment variables based on scope
    switch ($Scope) {
      'All' {
        return Get-EnvVarsFromAllScopes
      }
      default {
        try {
          return [System.Environment]::GetEnvironmentVariables($Scope)
        }
        catch {
          Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "Could not access $Scope environment variables: $($_.Exception.Message)"
          return @{}
        }
      }
    }
  }
  else {
    # Get specific environment variable
    $value = $null

    if ($Scope -eq 'All') {
      # Check all scopes, Process takes precedence
      foreach ($scopeToCheck in @('Process', 'User', 'Machine')) {
        try {
          $value = [System.Environment]::GetEnvironmentVariable($Name, $scopeToCheck)
          if ($null -ne $value) {
            break
          }
        }
        catch {
          Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Could not check $scopeToCheck scope for variable '$Name': $($_.Exception.Message)"
          continue
        }
      }
    }
    else {
      # Check specific scope
      try {
        $value = [System.Environment]::GetEnvironmentVariable($Name, $Scope)
      }
      catch {
        Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "Could not access environment variable '$Name' from $Scope scope: $($_.Exception.Message)"
      }
    }

    # Return the value or default
    if ($null -ne $value) {
      return $value
    }
    else {
      return $Default
    }
  }
}

function Global:Get-EnvVarsFromAllScopes {
  [CmdletBinding()]
  param()

  # Use regular hashtable instead of ordered dictionary to avoid ContainsKey issue
  $allEnvVars = @{}

  # Process scope takes highest precedence, then User, then Machine
  foreach ($scope in @('Machine', 'User', 'Process')) {
    try {
      Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Attempting to access $scope environment variables..."

      # Try the original method first
      $vars = [System.Environment]::GetEnvironmentVariables($scope)

      foreach ($var in $vars.GetEnumerator()) {
        # Only add if not already present (Process scope wins)
        if (-not $allEnvVars.ContainsKey($var.Key)) {
          $allEnvVars[$var.Key] = $var.Value
        }
      }

      Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Successfully accessed $($vars.Count) variables from $scope scope"
    }
    catch {
      Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Primary method failed for $scope scope: $($_.Exception.Message)"

      # Try alternative methods based on scope
      try {
        switch ($scope) {
          'Process' {
            # Alternative: Use Get-ChildItem on Env: drive
            $vars = Get-ChildItem Env: -ErrorAction Stop
            foreach ($var in $vars) {
              if (-not $allEnvVars.ContainsKey($var.Name)) {
                $allEnvVars[$var.Name] = $var.Value
              }
            }
            Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Alternative method succeeded for Process scope"
          }
          'User' {
            # Alternative: Use registry for User scope
            $regPath = "HKCU:\Environment"
            if (Test-Path $regPath) {
              $regVars = Get-ItemProperty -Path $regPath -ErrorAction Stop
              $regVars.PSObject.Properties | Where-Object { $_.Name -notlike "PS*" } | ForEach-Object {
                if (-not $allEnvVars.ContainsKey($_.Name)) {
                  $allEnvVars[$_.Name] = $_.Value
                }
              }
              Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Alternative registry method succeeded for User scope"
            }
          }
          'Machine' {
            # Alternative: Use registry for Machine scope (requires admin)
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
            if (Test-Path $regPath) {
              $regVars = Get-ItemProperty -Path $regPath -ErrorAction Stop
              $regVars.PSObject.Properties | Where-Object { $_.Name -notlike "PS*" } | ForEach-Object {
                if (-not $allEnvVars.ContainsKey($_.Name)) {
                  $allEnvVars[$_.Name] = $_.Value
                }
              }
              Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Alternative registry method succeeded for Machine scope"
            }
          }
        }
      }
      catch {
        Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "Could not access $scope environment variables using any method: $($_.Exception.Message)"
        continue
      }
    }
  }

  if ($allEnvVars.Count -eq 0) {
    Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "No environment variables could be retrieved from any scope"
  }
  else {
    Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Total environment variables collected: $($allEnvVars.Count)"
  }

  return $allEnvVars
}

function Test-EnvVarAccess {
  [CmdletBinding()]
  param()

  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Diagnosing environment variable access..."

  # Test current user context
  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Current User Context:"
  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "  User: $($env:USERNAME)"
  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "  Domain: $($env:USERDOMAIN)"
  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "  Is Admin: $(([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator'))"

  # Test each scope individually
  foreach ($scope in @('Process', 'User', 'Machine')) {
    Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Testing $scope scope:"
    try {
      $vars = [System.Environment]::GetEnvironmentVariables($scope)
      Write-Pretty -Tag "Success" -ContextScope $script:ctxScope -OneLine -Message "  ✓ Success - Found $($vars.Count) variables"
    }
    catch {
      Write-Pretty -Tag "Error" -ContextScope $script:ctxScope -OneLine -Message "  ✗ Failed - $($_.Exception.Message)"
    }
  }

  # Test Env: drive access
  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Testing Env: drive access:"
  try {
    $envDriveVars = Get-ChildItem Env: -ErrorAction Stop
    Write-Pretty -Tag "Success" -ContextScope $script:ctxScope -OneLine -Message "  ✓ Success - Found $($envDriveVars.Count) variables"
  }
  catch {
    Write-Pretty -Tag "Error" -ContextScope $script:ctxScope -OneLine -Message "  ✗ Failed - $($_.Exception.Message)"
  }
}

Export-ModuleMember -Function @(
  'Get-Env',
  'Get-EnvVarsFromAllScopes',
  'Test-EnvVarAccess'
)
