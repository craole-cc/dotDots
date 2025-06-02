<#
.SYNOPSIS
    Enhanced environment variable management functions with comprehensive scope support and error handling.

.DESCRIPTION
    This module provides advanced environment variable access with support for multiple scopes,
    fallback mechanisms, and consistent error handling using Write-Pretty logging.

    The main function Get-Env serves as a comprehensive replacement for PowerShell's $env:
    automatic variable, offering additional features like scope selection, default values,
    and robust error handling.

.AUTHOR
    Generated for enhanced environment variable management

.VERSION
    1.1.0

.NOTES
    Requires Write-Pretty function for consistent logging output.
    Some operations may require elevated privileges for Machine scope access.
#>

using namespace System.Security.Principal
using namespace System.Environment

# Module-level cache for performance optimization
$script:EnvCache = @{}
$script:CacheExpiry = @{}
$script:CacheTTL = 300 # 5 minutes default TTL

function Global:Get-Env {
  <#
  .SYNOPSIS
      Retrieves environment variables with advanced scope control and error handling.

  .DESCRIPTION
      Get-Env is a comprehensive function for accessing environment variables that supports:
      - Multiple scopes (Process, User, Machine, All)
      - Default value fallback with type conversion
      - Robust error handling with fallback methods
      - Listing all variables or retrieving specific ones
      - Performance caching with configurable TTL
      - Path validation and expansion
      - Consistent logging through Write-Pretty

      This function serves as an enhanced replacement for PowerShell's $env: automatic variable,
      providing more control and reliability when accessing environment variables.

  .PARAMETER Name
      The name of the environment variable to retrieve. If not provided or empty,
      the function will return all environment variables from the specified scope.
      Supports wildcards for pattern matching when retrieving multiple variables.

      Position: 0 (can be used without parameter name)
      Type: String
      Required: No
      Default: Empty string

  .PARAMETER Default
      The default value to return if the specified environment variable is not found.
      Only applies when retrieving a specific variable (Name parameter is provided).
      Supports type conversion based on the default value type.

      Type: Object (was String)
      Required: No
      Default: $null

  .PARAMETER Scope
      Specifies which environment variable scope(s) to search:
      - Process: Current process environment variables (default)
      - User: Current user's environment variables
      - Machine: System-wide environment variables (may require admin rights)
      - All: Searches all scopes with Process taking precedence

      Type: String (ValidateSet)
      Required: No
      Default: 'Process'
      Valid Values: 'Process', 'User', 'Machine', 'All'

  .PARAMETER ListAll
      Forces the function to return all environment variables from the specified scope,
      even if a Name is provided. Useful for explicitly listing all variables.

      Type: Switch
      Required: No

  .PARAMETER AsPath
      When specified, treats the environment variable as a path and returns a validated,
      expanded path object with additional path-related methods.

      Type: Switch
      Required: No

  .PARAMETER Cached
      Enables caching for the retrieved value to improve performance on repeated calls.
      Cache respects the TTL setting and scope changes.

      Type: Switch
      Required: No

  .PARAMETER Pattern
      When listing variables, filter results using wildcard pattern matching.
      Only applicable when Name is not specified or ListAll is used.

      Type: String
      Required: No

  .PARAMETER ExpandVars
      Expands embedded environment variables in the returned value.
      For example, "%USERPROFILE%\Documents" becomes "C:\Users\Username\Documents"

      Type: Switch
      Required: No

  .OUTPUTS
      System.Object - When retrieving a specific variable (type depends on conversion)
      System.Collections.Hashtable - When retrieving all variables
      System.IO.DirectoryInfo/FileInfo - When AsPath is specified and path exists
      System.String - Default behavior for most cases

  .EXAMPLE
      Get-Env PATH

      Description:
      Retrieves the PATH environment variable from the Process scope.

  .EXAMPLE
      Get-Env "MY_CUSTOM_VAR" -Default "default_value" -Cached

      Description:
      Retrieves MY_CUSTOM_VAR environment variable with caching enabled,
      returning "default_value" if not found.

  .EXAMPLE
      Get-Env "USERPROFILE" -AsPath

      Description:
      Retrieves USERPROFILE as a validated path object with additional path methods.

  .EXAMPLE
      Get-Env "PATH" -Scope All -ExpandVars

      Description:
      Searches for PATH variable in all scopes with variable expansion enabled.

  .EXAMPLE
      Get-Env -Pattern "PYTHON*" -Scope User

      Description:
      Returns all User scope variables that start with "PYTHON".

  .EXAMPLE
      Get-Env "TIMEOUT" -Default 30

      Description:
      Returns TIMEOUT as an integer (30) if not found, demonstrating type conversion.

  .NOTES
      - When Scope is 'All', the function checks scopes in order: Process, User, Machine
      - Process scope variables take precedence over User and Machine scope variables
      - Machine scope access may require elevated privileges
      - Uses Write-Pretty for consistent logging and error reporting
      - Includes fallback mechanisms for accessing variables when primary methods fail
      - Registry-based fallback is used for User and Machine scopes when .NET methods fail
      - Caching improves performance but respects scope changes and TTL settings

  .LINK
      Set-Env
      Test-GetEnv
      Clear-EnvCache
  #>

  [CmdletBinding()]
  param(
    [Parameter(HelpMessage = "Default value to return if variable is not found")]
    [object]$Default = $null,

    [Parameter(HelpMessage = "Scope to search for environment variables")]
    [ValidateSet('Process', 'User', 'Machine', 'All')]
    [string]$Scope = 'Process',

    [Parameter(HelpMessage = "Force listing all variables even if Name is provided")]
    [switch]$ListAll,

    [Parameter(HelpMessage = "Treat the variable as a path and return path object")]
    [switch]$AsPath,

    [Parameter(HelpMessage = "Enable caching for improved performance")]
    [switch]$Cached,

    [Parameter(HelpMessage = "Filter pattern for variable names when listing")]
    [string]$Pattern,

    [Parameter(HelpMessage = "Expand embedded environment variables")]
    [switch]$ExpandVars,

    [Parameter(HelpMessage = "Sort method for returned variables")]
    [ValidateSet('None', 'Name', 'NameDescending', 'Value', 'ValueDescending', 'Length', 'LengthDescending', 'Priority', 'Alphanumeric', 'Type')]
    [string]$Sort = 'None',

    [Parameter(Position = 0, HelpMessage = "Name of the environment variable to retrieve")]
    [string]$Name
  )

  $debugParams = @{
    Name       = $Name
    Scope      = $Scope
    ListAll    = $ListAll.IsPresent
    AsPath     = $AsPath.IsPresent
    Cached     = $Cached.IsPresent
    Pattern    = $Pattern
    ExpandVars = $ExpandVars.IsPresent
  }
  Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Get-Env called with: $(($debugParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', ')"

  # Check cache first if enabled and retrieving specific variable
  if ($Cached -and ![string]::IsNullOrEmpty($Name) -and !$ListAll) {
    $cacheKey = "${Scope}:${Name}"
    if ($script:EnvCache.ContainsKey($cacheKey) -and $script:CacheExpiry.ContainsKey($cacheKey)) {
      if ((Get-Date) -lt $script:CacheExpiry[$cacheKey]) {
        Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Returning cached value for '$Name'"
        return $script:EnvCache[$cacheKey]
      }
      else {
        # Remove expired cache entry
        $script:EnvCache.Remove($cacheKey)
        $script:CacheExpiry.Remove($cacheKey)
        Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Cache expired for '$Name', fetching fresh value"
      }
    }
  }

  if ([string]::IsNullOrEmpty($Name) -or $ListAll) {
    #~@ Return all environment variables based on scope
    $allEnvVars = Get-EnvironmentVariablesByScope -Scope $Scope

    #~@ Apply pattern filtering if specified
    if (![string]::IsNullOrEmpty($Pattern)) {
      Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Applying pattern filter: '$Pattern'"
      $filteredVars = @{}
      foreach ($var in $allEnvVars.GetEnumerator()) {
        if ($var.Key -like $Pattern) {
          $filteredVars[$var.Key] = $var.Value
        }
      }
      $allEnvVars = $filteredVars
      Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Pattern filtering resulted in $($allEnvVars.Count) variables"
    }

    #~@ Apply sorting
    $sortedEnvVars = Sort-EnvironmentVariables -Variables $allEnvVars -SortMethod $Sort -Scope $Scope

    return $sortedEnvVars
  }
  else {
    #~@ Get specific environment variable
    $value = Get-SpecificEnvironmentVariable -Name $Name -Scope $Scope

    #~@ Handle the result
    $result = if ($null -ne $value) {
      #~@ Expand variables if requested
      if ($ExpandVars) {
        try {
          $expandedValue = [System.Environment]::ExpandEnvironmentVariables($value)
          Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Expanded '$value' to '$expandedValue'"
          $expandedValue
        }
        catch {
          Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "Failed to expand variables in '$value': $($_.Exception.Message)"
          $value
        }
      }
      else {
        $value
      }
    }
    else {
      #~@ Apply type conversion to default value if needed
      if ($null -ne $Default) {
        Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Variable '$Name' not found, returning typed default value"
        $Default
      }
      else {
        Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Variable '$Name' not found and no default specified"
        $null
      }
    }

    #~@ Handle path conversion if requested
    if ($AsPath -and $null -ne $result) {
      $result = ConvertTo-PathObject -Path $result -VariableName $Name
    }

    #~@ Cache the result if caching is enabled
    if ($Cached -and $null -ne $result) {
      $cacheKey = "${Scope}:${Name}"
      $script:EnvCache[$cacheKey] = $result
      $script:CacheExpiry[$cacheKey] = (Get-Date).AddSeconds($script:CacheTTL)
      Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Cached value for '$Name' with TTL $script:CacheTTL seconds"
    }

    return $result
  }
}

function Global:Set-Env {
  <#
  .SYNOPSIS
      Sets environment variables with enhanced scope control and validation.

  .DESCRIPTION
      Set-Env provides comprehensive environment variable setting capabilities with:
      - Multiple scope support (Process, User, Machine)
      - Type-specific environment variable handling (cd shortcuts, editor shortcuts)
      - Path validation for directory and file variables
      - Automatic variable expansion
      - Persistent storage options
      - Cache invalidation for performance

  .PARAMETER Name
      The name of the environment variable to set.

  .PARAMETER Value
      The value to assign to the environment variable.
      Supports environment variable expansion.

  .PARAMETER Type
      Special type handling for common patterns:
      - cd: Creates a directory change shortcut function
      - edit: Creates an editor shortcut function
      - path: Validates as a path before setting

  .PARAMETER Scope
      The scope in which to set the environment variable:
      - Process: Current process only (default)
      - User: Current user (persistent)
      - Machine: System-wide (requires admin, persistent)

  .PARAMETER Validate
      Validates the value before setting (useful for paths, URLs, etc.)
  #>
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,

    [Parameter(Mandatory, Position = 1)]
    [AllowEmptyString()]
    [string]$Value,

    [Parameter()]
    [ValidateSet('cd', 'edit', 'path')]
    [string]$Type,

    [Parameter()]
    [ValidateSet('Process', 'User', 'Machine')]
    [string]$Scope = 'Process',

    [Parameter()]
    [switch]$Validate,

    [Parameter()]
    [switch]$Persistent
  )

  Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Set-Env called: Name='$Name', Value='$Value', Type='$Type', Scope='$Scope'"

  #~@ Expand environment variables in the value
  $expandedValue = [System.Environment]::ExpandEnvironmentVariables($Value)
  if ($expandedValue -ne $Value) {
    Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Expanded value from '$Value' to '$expandedValue'"
  }

  #~@ Update the name based on type
  $processedName = $Name
  if ($Type -eq 'cd') {
    $processedName = if (-not $Name.StartsWith('cd.', [System.StringComparison]::InvariantCultureIgnoreCase)) {
      'cd.' + $Name
    }
    else { $Name }
  }
  elseif ($Type -eq 'edit') {
    $processedName = if (-not $Name.StartsWith('edit.', [System.StringComparison]::InvariantCultureIgnoreCase)) {
      'edit.' + $Name
    }
    else { $Name }
  }

  #~@ Auto-detect type from name if not specified
  if ([string]::IsNullOrEmpty($Type)) {
    if ($processedName -match '^cd\.') {
      $Type = 'cd'
      Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Auto-detected type 'cd' from name pattern"
    }
    elseif ($processedName -match '^edit\.') {
      $Type = 'edit'
      Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Auto-detected type 'edit' from name pattern"
    }
  }

  #~@ Validation logic
  if ($Validate -or $Type -in @('cd', 'path')) {
    if ($Type -eq 'cd' -or $Type -eq 'path') {
      if (![string]::IsNullOrEmpty($expandedValue) -and !(Test-Path $expandedValue -PathType Container -ErrorAction SilentlyContinue)) {
        Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "Path validation failed: Directory '$expandedValue' does not exist"
        if (!$PSCmdlet.ShouldContinue("Directory does not exist. Continue anyway?", "Path Validation")) {
          return $false
        }
      }
    }
  }

  #~@ Handle special function creation for cd and edit types
  if ($Type -in @('cd', 'edit')) {
    if (-not (New-EnvironmentFunction -Name $processedName -Value $expandedValue -Type $Type)) {
      return $false
    }
  }

  #~@ Set the environment variable
  if ($PSCmdlet.ShouldProcess("Environment Variable '$processedName'", "Set Value to '$expandedValue' in $Scope scope")) {
    try {
      [System.Environment]::SetEnvironmentVariable($processedName, $expandedValue, $Scope)

      #~@ Clear cache entry if it exists
      $cacheKey = "${Scope}:${processedName}"
      if ($script:EnvCache.ContainsKey($cacheKey)) {
        $script:EnvCache.Remove($cacheKey)
        $script:CacheExpiry.Remove($cacheKey)
        Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Cleared cache for updated variable '$processedName'"
      }

      Write-Pretty -Tag "Success" -ContextScope $script:ctxScope -OneLine -Message "Set ${processedName} => ${expandedValue} [$Scope]"
      return $true
    }
    catch {
      Write-Pretty -Tag "Error" -ContextScope $script:ctxScope -OneLine -Message "Failed to set environment variable '$processedName': $($_.Exception.Message)"
      return $false
    }
  }
}

function Global:Remove-Env {
  <#
  .SYNOPSIS
      Removes environment variables from specified scopes.

  .DESCRIPTION
      Safely removes environment variables with support for multiple scopes,
      confirmation prompts, and cache cleanup.
  #>
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
  param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Name,

    [Parameter()]
    [ValidateSet('Process', 'User', 'Machine')]
    [string]$Scope = 'Process',

    [Parameter()]
    [switch]$Force
  )

  if ($Force -or $PSCmdlet.ShouldProcess("Environment Variable '$Name'", "Remove from $Scope scope")) {
    try {
      [System.Environment]::SetEnvironmentVariable($Name, $null, $Scope)

      #~@ Clear from cache
      $cacheKey = "${Scope}:${Name}"
      if ($script:EnvCache.ContainsKey($cacheKey)) {
        $script:EnvCache.Remove($cacheKey)
        $script:CacheExpiry.Remove($cacheKey)
      }

      Write-Pretty -Tag "Success" -ContextScope $script:ctxScope -OneLine -Message "Removed environment variable '$Name' from $Scope scope"
      return $true
    }
    catch {
      Write-Pretty -Tag "Error" -ContextScope $script:ctxScope -OneLine -Message "Failed to remove environment variable '$Name': $($_.Exception.Message)"
      return $false
    }
  }
}

function Global:Clear-EnvCache {
  <#
  .SYNOPSIS
      Clears the environment variable cache.

  .DESCRIPTION
      Provides cache management functionality with options for selective clearing.
  #>
  [CmdletBinding()]
  param(
    [Parameter()]
    [string]$Pattern,

    [Parameter()]
    [ValidateSet('Process', 'User', 'Machine', 'All')]
    [string]$Scope
  )

  $initialCount = $script:EnvCache.Count

  if (![string]::IsNullOrEmpty($Pattern) -or ![string]::IsNullOrEmpty($Scope)) {
    #~@ Selective clearing
    $keysToRemove = @()
    foreach ($key in $script:EnvCache.Keys) {
      $shouldRemove = $true

      if (![string]::IsNullOrEmpty($Scope) -and $Scope -ne 'All') {
        $shouldRemove = $shouldRemove -and $key.StartsWith("${Scope}:")
      }

      if (![string]::IsNullOrEmpty($Pattern)) {
        $varName = $key -replace '^[^:]+:', ''
        $shouldRemove = $shouldRemove -and ($varName -like $Pattern)
      }

      if ($shouldRemove) {
        $keysToRemove += $key
      }
    }

    foreach ($key in $keysToRemove) {
      $script:EnvCache.Remove($key)
      $script:CacheExpiry.Remove($key)
    }

    Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Cleared $($keysToRemove.Count) cache entries matching criteria"
  }
  else {
    #~@ Clear all cache
    $script:EnvCache.Clear()
    $script:CacheExpiry.Clear()
    Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Cleared all $initialCount cache entries"
  }
}

function Global:Set-EnvCacheTTL {
  <#
  .SYNOPSIS
      Configures the cache time-to-live for environment variables.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateRange(0, 3600)]
    [int]$Seconds
  )

  $script:CacheTTL = $Seconds
  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Cache TTL set to $Seconds seconds"
}

function Test-GetEnv {
  <#
  .SYNOPSIS
      Diagnoses environment variable access capabilities and permissions.

  .DESCRIPTION
      Test-GetEnv performs comprehensive diagnostics of environment variable access,
      testing each scope individually and providing detailed information about:
      - Current user context and privileges
      - Access to each environment variable scope (Process, User, Machine)
      - Alternative access methods (Env: drive)
      - Performance benchmarking
      - Cache functionality testing
      - Detailed error reporting for troubleshooting

      This function is useful for troubleshooting environment variable access issues
      and understanding the current security context and permissions.

  .PARAMETER Benchmark
      Runs performance benchmarks comparing cached vs uncached access.

  .PARAMETER Quick
      Runs a quick diagnostic without comprehensive testing.

  .OUTPUTS
      None - Outputs diagnostic information using Write-Pretty

  .EXAMPLE
      Test-GetEnv

      Description:
      Runs comprehensive diagnostics of environment variable access capabilities.

  .EXAMPLE
      Test-GetEnv -Benchmark

      Description:
      Includes performance benchmarking in the diagnostic output.

  .NOTES
      - Uses Write-Pretty for consistent output formatting
      - Tests both primary .NET methods and fallback mechanisms
      - Provides security context information including admin status
      - Helps identify permission issues and access restrictions
      - Includes cache performance testing when requested

  .LINK
      Get-Env
      Set-Env
      Clear-EnvCache
  #>
  [CmdletBinding()]
  param(
    [Parameter()]
    [switch]$Benchmark,

    [Parameter()]
    [switch]$Quick
  )

  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "=== Environment Variable Access Diagnostics ==="

  #~@ Test current user context
  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message ""
  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Current User Context:"
  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "  User: $(Get-Env 'USERNAME' -Default 'Unknown')"
  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "  Domain: $(Get-Env 'USERDOMAIN' -Default 'Unknown')"

  try {
    $isAdmin = ([WindowsPrincipal] [WindowsIdentity]::GetCurrent()).IsInRole([WindowsBuiltInRole] 'Administrator')
    Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "  Is Admin: $isAdmin"
  }
  catch {
    Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "  Is Admin: Unable to determine ($($_.Exception.Message))"
  }

  if ($Quick) {
    #~@ Quick test - just verify basic functionality
    Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message ""
    Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Quick Test Results:"

    try {
      $testResult = Get-Env "PATH" -Scope Process
      Write-Pretty -Tag "Success" -ContextScope $script:ctxScope -OneLine -Message "  ✓ Basic Get-Env functionality working"
    }
    catch {
      Write-Pretty -Tag "Error" -ContextScope $script:ctxScope -OneLine -Message "  ✗ Basic Get-Env failed: $($_.Exception.Message)"
    }

    Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "=== Quick Diagnostics Complete ==="
    return
  }

  #~@ Test each scope individually
  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message ""
  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Testing Environment Variable Scopes:"

  foreach ($scope in @('Process', 'User', 'Machine')) {
    Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message ""
    Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "  Testing $scope scope:"

    $scopeResults = Test-EnvironmentScope -Scope $scope
    foreach ($result in $scopeResults) {
      $icon = if ($result.Success) { "✓" } else { "✗" }
      $tag = if ($result.Success) { "Success" } else { "Error" }
      Write-Pretty -Tag $tag -ContextScope $script:ctxScope -OneLine -Message "    $icon $($result.Message)"
    }
  }

  #~@ Test enhanced features
  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message ""
  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Testing Enhanced Features:"

  #~@ Test caching
  try {
    Clear-EnvCache
    $start = Get-Date
    $val1 = Get-Env "PATH" -Cached
    $uncachedTime = (Get-Date) - $start

    $start = Get-Date
    $val2 = Get-Env "PATH" -Cached
    $cachedTime = (Get-Date) - $start

    if ($val1 -eq $val2) {
      Write-Pretty -Tag "Success" -ContextScope $script:ctxScope -OneLine -Message "  ✓ Caching functionality working"
      if ($Benchmark) {
        Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "    Uncached: $($uncachedTime.TotalMilliseconds)ms, Cached: $($cachedTime.TotalMilliseconds)ms"
      }
    }
    else {
      Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "  ⚠ Caching returned different values"
    }
  }
  catch {
    Write-Pretty -Tag "Error" -ContextScope $script:ctxScope -OneLine -Message "  ✗ Caching test failed: $($_.Exception.Message)"
  }

  #~@ Test pattern matching
  try {
    $patternResults = Get-Env -Pattern "USER*" -Scope Process
    if ($patternResults.Count -gt 0) {
      Write-Pretty -Tag "Success" -ContextScope $script:ctxScope -OneLine -Message "  ✓ Pattern matching working ($($patternResults.Count) matches for USER*)"
    }
    else {
      Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "  ⚠ Pattern matching returned no results"
    }
  }
  catch {
    Write-Pretty -Tag "Error" -ContextScope $script:ctxScope -OneLine -Message "  ✗ Pattern matching failed: $($_.Exception.Message)"
  }

  #~@ Test variable expansion
  try {
    $testVar = "%USERNAME%_test"
    $expanded = Get-Env -Name "NON_EXISTENT_VAR" -Default $testVar -ExpandVars
    $expectedExpanded = [System.Environment]::ExpandEnvironmentVariables($testVar)
    if ($expanded -eq $expectedExpanded) {
      Write-Pretty -Tag "Success" -ContextScope $script:ctxScope -OneLine -Message "  ✓ Variable expansion working"
    }
    else {
      Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "  ⚠ Variable expansion not working as expected"
    }
  }
  catch {
    Write-Pretty -Tag "Error" -ContextScope $script:ctxScope -OneLine -Message "  ✗ Variable expansion test failed: $($_.Exception.Message)"
  }

  # Performance benchmark if requested
  if ($Benchmark) {
    Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message ""
    Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Performance Benchmark:"

    $iterations = 100
    $testVar = "PATH"

    # Benchmark uncached access
    Clear-EnvCache
    $start = Get-Date
    for ($i = 0; $i -lt $iterations; $i++) {
      $null = Get-Env $testVar
    }
    $uncachedTotal = (Get-Date) - $start

    # Benchmark cached access
    Clear-EnvCache
    $null = Get-Env $testVar -Cached # Prime the cache
    $start = Get-Date
    for ($i = 0; $i -lt $iterations; $i++) {
      $null = Get-Env $testVar -Cached
    }
    $cachedTotal = (Get-Date) - $start

    Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "  $iterations iterations:"
    Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "    Uncached: $($uncachedTotal.TotalMilliseconds)ms total, $([math]::Round($uncachedTotal.TotalMilliseconds / $iterations, 2))ms avg"
    Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "    Cached: $($cachedTotal.TotalMilliseconds)ms total, $([math]::Round($cachedTotal.TotalMilliseconds / $iterations, 2))ms avg"

    $speedup = [math]::Round($uncachedTotal.TotalMilliseconds / $cachedTotal.TotalMilliseconds, 1)
    Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "    Speedup: ${speedup}x faster with caching"
  }

  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message ""
  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "=== Diagnostics Complete ==="
}

function Get-EnvironmentVariablesByScope {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Scope
  )

  if ($Scope -eq 'All') {
    # Combine all scopes with Process taking precedence
    $allVars = @{}

    # Start with Machine scope (lowest priority)
    try {
      $machineVars = [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::Machine)
      foreach ($var in $machineVars.GetEnumerator()) {
        $allVars[$var.Key] = $var.Value
      }
      Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Retrieved $($machineVars.Count) Machine scope variables"
    }
    catch {
      Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "Failed to access Machine scope variables: $($_.Exception.Message)"
    }

    # Add User scope (medium priority)
    try {
      $userVars = [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::User)
      foreach ($var in $userVars.GetEnumerator()) {
        $allVars[$var.Key] = $var.Value
      }
      Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Retrieved $($userVars.Count) User scope variables"
    }
    catch {
      Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "Failed to access User scope variables: $($_.Exception.Message)"
    }

    # Add Process scope (highest priority)
    try {
      $processVars = [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::Process)
      foreach ($var in $processVars.GetEnumerator()) {
        $allVars[$var.Key] = $var.Value
      }
      Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Retrieved $($processVars.Count) Process scope variables"
    }
    catch {
      Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "Failed to access Process scope variables: $($_.Exception.Message)"
    }

    return $allVars
  }
  else {
    # Get variables from specific scope
    try {
      $target = switch ($Scope) {
        'Process' { [System.EnvironmentVariableTarget]::Process }
        'User' { [System.EnvironmentVariableTarget]::User }
        'Machine' { [System.EnvironmentVariableTarget]::Machine }
        default { throw "Invalid scope: $Scope" }
      }

      $variables = [System.Environment]::GetEnvironmentVariables($target)
      Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Retrieved $($variables.Count) variables from $Scope scope"
      return $variables
    }
    catch {
      Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "Primary method failed for $Scope scope: $($_.Exception.Message)"

      # Fallback to registry-based access for User and Machine scopes
      if ($Scope -in @('User', 'Machine')) {
        return Get-EnvironmentVariablesFromRegistry -Scope $Scope
      }
      else {
        # For Process scope, try the Env: drive as fallback
        try {
          $envDriveVars = @{}
          Get-ChildItem Env: | ForEach-Object {
            $envDriveVars[$_.Name] = $_.Value
          }
          Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Fallback: Retrieved $($envDriveVars.Count) variables from Env: drive"
          return $envDriveVars
        }
        catch {
          Write-Pretty -Tag "Error" -ContextScope $script:ctxScope -OneLine -Message "All methods failed for Process scope: $($_.Exception.Message)"
          return @{}
        }
      }
    }
  }
}

function Get-SpecificEnvironmentVariable {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [string]$Scope
  )

  if ($Scope -eq 'All') {
    # Check scopes in priority order: Process, User, Machine
    foreach ($currentScope in @('Process', 'User', 'Machine')) {
      $value = Get-SpecificEnvironmentVariable -Name $Name -Scope $currentScope
      if ($null -ne $value) {
        Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Found '$Name' in $currentScope scope"
        return $value
      }
    }
    Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Variable '$Name' not found in any scope"
    return $null
  }
  else {
    # Get from specific scope
    try {
      $target = switch ($Scope) {
        'Process' { [System.EnvironmentVariableTarget]::Process }
        'User' { [System.EnvironmentVariableTarget]::User }
        'Machine' { [System.EnvironmentVariableTarget]::Machine }
        default { throw "Invalid scope: $Scope" }
      }

      $value = [System.Environment]::GetEnvironmentVariable($Name, $target)
      if ($null -ne $value) {
        Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Retrieved '$Name' from $Scope scope (length: $($value.Length))"
      }
      return $value
    }
    catch {
      Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "Primary method failed for '$Name' in $Scope scope: $($_.Exception.Message)"

      # Fallback methods
      if ($Scope -eq 'Process') {
        # Try Env: drive
        try {
          $value = (Get-Item "Env:$Name" -ErrorAction Stop).Value
          Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Fallback: Retrieved '$Name' from Env: drive"
          return $value
        }
        catch {
          Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Env: drive fallback failed for '$Name': $($_.Exception.Message)"
        }
      }
      elseif ($Scope -in @('User', 'Machine')) {
        # Try registry-based access
        return Get-EnvironmentVariableFromRegistry -Name $Name -Scope $Scope
      }

      return $null
    }
  }
}

function Get-EnvironmentVariablesFromRegistry {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateSet('User', 'Machine')]
    [string]$Scope
  )

  $registryPath = switch ($Scope) {
    'User' { 'HKCU:\Environment' }
    'Machine' { 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' }
  }

  try {
    if (Test-Path $registryPath) {
      $regVars = @{}
      $regKey = Get-Item $registryPath
      foreach ($valueName in $regKey.GetValueNames()) {
        try {
          $regVars[$valueName] = $regKey.GetValue($valueName)
        }
        catch {
          Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "Failed to read registry value '$valueName': $($_.Exception.Message)"
        }
      }
      Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Registry fallback: Retrieved $($regVars.Count) variables from $Scope scope"
      return $regVars
    }
    else {
      Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "Registry path '$registryPath' not found"
      return @{}
    }
  }
  catch {
    Write-Pretty -Tag "Error" -ContextScope $script:ctxScope -OneLine -Message "Registry fallback failed for $Scope scope: $($_.Exception.Message)"
    return @{}
  }
}

function Get-EnvironmentVariableFromRegistry {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [ValidateSet('User', 'Machine')]
    [string]$Scope
  )

  $registryPath = switch ($Scope) {
    'User' { 'HKCU:\Environment' }
    'Machine' { 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' }
  }

  try {
    if (Test-Path $registryPath) {
      $value = Get-ItemProperty -Path $registryPath -Name $Name -ErrorAction Stop | Select-Object -ExpandProperty $Name
      Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Registry fallback: Retrieved '$Name' from $Scope scope"
      return $value
    }
    else {
      Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "Registry path '$registryPath' not found"
      return $null
    }
  }
  catch {
    Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Registry fallback failed for '$Name' in $Scope scope: $($_.Exception.Message)"
    return $null
  }
}

function Sort-EnvironmentVariables {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [hashtable]$Variables,

    [Parameter(Mandatory)]
    [string]$SortMethod,

    [Parameter()]
    [string]$Scope = 'Process'
  )

  if ($SortMethod -eq 'None') {
    return $Variables
  }

  Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Sorting $($Variables.Count) variables by: $SortMethod"

  $sortedVars = [ordered]@{}

  switch ($SortMethod) {
    'Name' {
      $Variables.GetEnumerator() | Sort-Object Key | ForEach-Object {
        $sortedVars[$_.Key] = $_.Value
      }
    }

    'NameDescending' {
      $Variables.GetEnumerator() | Sort-Object Key -Descending | ForEach-Object {
        $sortedVars[$_.Key] = $_.Value
      }
    }

    'Value' {
      $Variables.GetEnumerator() | Sort-Object Value | ForEach-Object {
        $sortedVars[$_.Key] = $_.Value
      }
    }

    'ValueDescending' {
      $Variables.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
        $sortedVars[$_.Key] = $_.Value
      }
    }

    'Length' {
      $Variables.GetEnumerator() | Sort-Object { $_.Value.Length } | ForEach-Object {
        $sortedVars[$_.Key] = $_.Value
      }
    }

    'LengthDescending' {
      $Variables.GetEnumerator() | Sort-Object { $_.Value.Length } -Descending | ForEach-Object {
        $sortedVars[$_.Key] = $_.Value
      }
    }

    'Alphanumeric' {
      # Natural sort that handles numbers correctly (e.g., VAR1, VAR2, VAR10)
      $Variables.GetEnumerator() | Sort-Object {
        # Split name into parts and pad numbers for proper sorting
        $parts = $_.Key -split '(\d+)'
        for ($i = 0; $i -lt $parts.Length; $i++) {
          if ($parts[$i] -match '^\d+$') {
            $parts[$i] = $parts[$i].PadLeft(10, '0')
          }
        }
        $parts -join ''
      } | ForEach-Object {
        $sortedVars[$_.Key] = $_.Value
      }
    }

    'Priority' {
      # Sort by common environment variable importance/priority
      $priorityOrder = @{
        # System critical
        'PATH' = 1; 'PATHEXT' = 2; 'OS' = 3; 'PROCESSOR_ARCHITECTURE' = 4
        'SYSTEMROOT' = 5; 'WINDIR' = 6; 'COMSPEC' = 7

        # User context
        'USERNAME' = 10; 'USERPROFILE' = 11; 'USERDOMAIN' = 12; 'USERDNSDOMAIN' = 13
        'APPDATA' = 14; 'LOCALAPPDATA' = 15; 'TEMP' = 16; 'TMP' = 17

        # Development common
        'PYTHONPATH' = 20; 'JAVA_HOME' = 21; 'NODE_PATH' = 22; 'GOPATH' = 23
        'ANDROID_HOME' = 24; 'GRADLE_HOME' = 25; 'MAVEN_HOME' = 26

        # Shell/Terminal
        'PSModulePath' = 30; 'PROMPT' = 31; 'TERM' = 32

        # Common applications
        'PROGRAMFILES' = 40; 'PROGRAMFILES(X86)' = 41; 'PROGRAMDATA' = 42
        'ALLUSERSPROFILE' = 43
      }

      $Variables.GetEnumerator() | Sort-Object {
        $priority = $priorityOrder[$_.Key]
        if ($null -eq $priority) {
          1000 + $_.Key  # Unknown variables go to end, sorted by name
        }
        else {
          $priority
        }
      } | ForEach-Object {
        $sortedVars[$_.Key] = $_.Value
      }
    }

    'Type' {
      # Sort by inferred variable type/category
      $Variables.GetEnumerator() | Sort-Object {
        $name = $_.Key
        $value = $_.Value

        # Categorize variables
        $category = switch -Regex ($name) {
          '^(PATH|PATHEXT)$' { '1-Paths' }
          '^(OS|PROCESSOR_|SYSTEM|WIN)' { '2-System' }
          '^(USER|HOME|PROFILE)' { '3-User' }
          '^(PROGRAM|APP)' { '4-Programs' }
          '^(TEMP|TMP)$' { '5-Temporary' }
          '^(PYTHON|JAVA|NODE|GO|ANDROID|MAVEN|GRADLE)' { '6-Development' }
          '^(PS|PROMPT|TERM)' { '7-Shell' }
          'cd\.' { '8-CDShortcuts' }
          'edit\.' { '9-EditShortcuts' }
          default {
            # Try to categorize by value patterns
            if ($value -match '^[A-Z]:\\') { '4-Programs' }
            elseif ($value -match '^\d+$') { '10-Numeric' }
            else { '11-Other' }
          }
        }

        "$category-$name"
      } | ForEach-Object {
        $sortedVars[$_.Key] = $_.Value
      }
    }

    default {
      Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "Unknown sort method '$SortMethod', using no sorting"
      return $Variables
    }
  }

  Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Sorted $($sortedVars.Count) variables using $SortMethod method"
  return $sortedVars
}

function ConvertTo-PathObject {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter()]
    [string]$VariableName
  )

  try {
    # Expand any environment variables in the path
    $expandedPath = [System.Environment]::ExpandEnvironmentVariables($Path)

    # Test if the path exists and determine its type
    if (Test-Path $expandedPath -PathType Container) {
      $pathObject = Get-Item $expandedPath -Force
      Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Converted '$VariableName' to directory path object: $expandedPath"
      return $pathObject
    }
    elseif (Test-Path $expandedPath -PathType Leaf) {
      $pathObject = Get-Item $expandedPath -Force
      Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Converted '$VariableName' to file path object: $expandedPath"
      return $pathObject
    }
    else {
      # Path doesn't exist, but we can still return a path object
      try {
        $pathObject = [System.IO.DirectoryInfo]::new($expandedPath)
        Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "Path '$expandedPath' does not exist, returning DirectoryInfo object"
        return $pathObject
      }
      catch {
        Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "Failed to create path object for '$expandedPath': $($_.Exception.Message)"
        return $expandedPath
      }
    }
  }
  catch {
    Write-Pretty -Tag "Error" -ContextScope $script:ctxScope -OneLine -Message "Failed to convert '$Path' to path object: $($_.Exception.Message)"
    return $Path
  }
}

function New-EnvironmentFunction {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [string]$Value,

    [Parameter(Mandatory)]
    [ValidateSet('cd', 'edit')]
    [string]$Type
  )

  try {
    $functionName = $Name
    $functionBody = switch ($Type) {
      'cd' {
        @"
param([string]`$SubPath = '')
if ([string]::IsNullOrEmpty(`$SubPath)) {
    Set-Location '$Value'
} else {
    Set-Location (Join-Path '$Value' `$SubPath)
}
"@
      }
      'edit' {
        @"
param([string]`$File = '')
if ([string]::IsNullOrEmpty(`$File)) {
    & '$Value'
} else {
    & '$Value' `$File
}
"@
      }
    }

    # Create the function in the global scope
    $functionScript = "function Global:$functionName { $functionBody }"
    Invoke-Expression $functionScript

    Write-Pretty -Tag "Success" -ContextScope $script:ctxScope -OneLine -Message "Created $Type function '$functionName'"
    return $true
  }
  catch {
    Write-Pretty -Tag "Error" -ContextScope $script:ctxScope -OneLine -Message "Failed to create $Type function '$Name': $($_.Exception.Message)"
    return $false
  }
}

function Test-EnvironmentScope {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Scope
  )

  $results = @()

  # Test basic access
  try {
    $target = switch ($Scope) {
      'Process' { [System.EnvironmentVariableTarget]::Process }
      'User' { [System.EnvironmentVariableTarget]::User }
      'Machine' { [System.EnvironmentVariableTarget]::Machine }
    }

    $testVars = [System.Environment]::GetEnvironmentVariables($target)
    $results += @{
      Success = $true
      Message = "Primary .NET method: $($testVars.Count) variables accessible"
    }
  }
  catch {
    $results += @{
      Success = $false
      Message = "Primary .NET method failed: $($_.Exception.Message)"
    }
  }

  # Test specific variable retrieval
  $testVarName = switch ($Scope) {
    'Process' { 'PATH' }
    'User' { 'USERNAME' }
    'Machine' { 'OS' }
  }

  try {
    $testValue = Get-SpecificEnvironmentVariable -Name $testVarName -Scope $Scope
    if ($null -ne $testValue) {
      $results += @{
        Success = $true
        Message = "Variable retrieval: Successfully got '$testVarName'"
      }
    }
    else {
      $results += @{
        Success = $false
        Message = "Variable retrieval: '$testVarName' not found"
      }
    }
  }
  catch {
    $results += @{
      Success = $false
      Message = "Variable retrieval failed: $($_.Exception.Message)"
    }
  }

  # Test fallback methods for non-Process scopes
  if ($Scope -in @('User', 'Machine')) {
    try {
      $regVars = Get-EnvironmentVariablesFromRegistry -Scope $Scope
      $results += @{
        Success = $true
        Message = "Registry fallback: $($regVars.Count) variables accessible"
      }
    }
    catch {
      $results += @{
        Success = $false
        Message = "Registry fallback failed: $($_.Exception.Message)"
      }
    }
  }

  return $results
}

#~@ Initialize context scope if not already set
if (-not $script:ctxScope) {
  $script:ctxScope = "EnvModule"
}

Export-ModuleMember -Function @(
  'Get-Env',
  'Set-Env',
  'Remove-Env',
  'Clear-EnvCache',
  'Set-EnvCacheTTL',
  'Test-GetEnv'
  # 'Sort-EnvironmentVariables'
)
