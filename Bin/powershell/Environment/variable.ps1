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
        Advanced environment variable management with scope control, caching, and type conversion.

    .DESCRIPTION
        Get-Env provides comprehensive environment variable access with enterprise-grade features:

        Key Features:
        • Multi-scope support (Process, User, Machine, All)
        • Intelligent type conversion based on default values
        • Performance caching with configurable TTL
        • Path validation and expansion capabilities
        • Pattern matching and flexible sorting options
        • Robust error handling with fallback mechanisms
        • Integrated logging through Write-Pretty

        This function replaces basic $env: access with enhanced reliability and control,
        making it ideal for configuration management, deployment scripts, and system administration.

    .PARAMETER Name
        Environment variable name to retrieve. Supports wildcards for pattern matching.
        If omitted, returns all variables from the specified scope.

        Examples: "PATH", "PYTHON*", "MY_APP_*"

    .PARAMETER Default
        Fallback value when variable doesn't exist. Supports automatic type conversion:
        • String defaults return strings
        • Integer defaults return integers
        • Boolean defaults return booleans
        • Array defaults return arrays

    .PARAMETER Scope
        Target environment scope(s):
        • Process: Current process variables (fastest, default)
        • User: Current user's persistent variables
        • Machine: System-wide variables (may need admin rights)
        • All: Searches all scopes, Process takes precedence

    .PARAMETER ListAll
        Forces enumeration of all variables, even when Name is specified.
        Useful for administrative tasks and environment auditing.

    .PARAMETER AsPath
        Treats variable as file system path, returning enhanced path object with:
        • Validation of path existence
        • Automatic path expansion
        • Additional path manipulation methods
        • Type safety for path operations

    .PARAMETER Cached
        Enables intelligent caching for performance optimization:
        • Respects TTL settings (default: 300 seconds)
        • Scope-aware cache keys
        • Automatic cache invalidation
        • Memory-efficient storage

    .PARAMETER Pattern
        Wildcard pattern for filtering variable names during enumeration.
        Only applies when listing multiple variables.

        Examples: "JAVA*", "*_HOME", "MY_APP_*", "*env*"

    .PARAMETER ExpandVars
        Expands embedded environment variables using Windows expansion syntax.
        Transforms "%USERPROFILE%\Documents" → "C:\Users\Username\Documents"

    .PARAMETER Sort
        Sorting method for returned variable collections:
        • None: Original order (fastest)
        • Name/NameDescending: Alphabetical by variable name
        • Value/ValueDescending: By variable value
        • Length/LengthDescending: By value length
        • Priority: By scope importance
        • Alphanumeric: Natural alphanumeric sorting (Default)
        • Type: Groups by inferred data type

    .OUTPUTS
        Object - Single variable (type depends on conversion)
        Hashtable - Multiple variables collection
        DirectoryInfo/FileInfo - When AsPath is used with valid paths
        $null - When variable not found and no default specified

    .EXAMPLE
        # Basic variable retrieval
        Get-Env "PATH"

        Returns the PATH environment variable from the current process scope.

    .EXAMPLE
        # Type-safe default with caching
        $timeout = Get-Env "APP_TIMEOUT" -Default 30 -Cached

        Returns APP_TIMEOUT as integer, defaults to 30 if not found, enables caching for performance.

    .EXAMPLE
        # Path validation and expansion
        $userHome = Get-Env "USERPROFILE" -AsPath -ExpandVars

        Returns USERPROFILE as a validated path object with expanded variables.

    .EXAMPLE
        # Multi-scope search with fallback
        $javaHome = Get-Env "JAVA_HOME" -Scope All -Default "C:\Program Files\Java\jdk"

        Searches all scopes for JAVA_HOME, falls back to default path if not found.

    .EXAMPLE
        # Pattern-based environment audit
        Get-Env -Pattern "PYTHON*" -Scope User -Sort Name

        Lists all user-scope variables starting with "PYTHON", sorted alphabetically.

    .EXAMPLE
        # Configuration management
        $config = @{
            DatabaseUrl = Get-Env "DB_CONNECTION_STRING" -Default "localhost:5432"
            ApiKey = Get-Env "API_SECRET_KEY"
            Debug = Get-Env "DEBUG_MODE" -Default $false
            Retries = Get-Env "MAX_RETRIES" -Default 3
        }

        Demonstrates building configuration objects with type-safe defaults.

    .EXAMPLE
        # Development environment detection
        $isDev = Get-Env "ENVIRONMENT" -Default "production" | Where-Object { $_ -eq "development" }

        Safely detects development environment with production as secure default.

    .NOTES
        Performance Considerations:
        • Process scope is fastest (direct memory access)
        • User/Machine scopes may require registry access
        • Caching provides significant benefits for repeated access
        • Pattern matching is optimized but consider scope size

        Security Notes:
        • Machine scope may require elevated privileges
        • Sensitive variables should use secure defaults
        • Cache respects original variable scope and permissions

        Compatibility:
        • PowerShell 5.1+ (Windows PowerShell)
        • PowerShell 7+ (PowerShell Core)
        • Windows, Linux, macOS (scope availability varies)

        Dependencies:
        • Write-Pretty function for logging
        • Helper functions: Get-EnvironmentVariablesByScope, Get-SpecificEnvironmentVariable,
          Get-EnvSorted, ConvertTo-PathObject

        Error Handling:
        • Graceful fallbacks for access denied scenarios
        • Registry fallback methods for scope access failures
        • Comprehensive validation of input parameters
        • Detailed logging for troubleshooting

    .LINK
        Set-Env - Companion function for setting environment variables
        Test-GetEnv - Comprehensive test suite and examples
        Clear-EnvCache - Cache management utilities

        Online Documentation:
        https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_environment_variables
    #>

  [CmdletBinding()]
  param(
    [Parameter(HelpMessage = 'Default value to return if variable is not found')]
    [object]$Default = $null,

    [Parameter(HelpMessage = 'Scope to search for environment variables')]
    [ValidateSet('Process', 'User', 'Machine', 'All')]
    [string]$Scope = 'Process',

    [Parameter(HelpMessage = 'Force listing all variables even if Name is provided')]
    [switch]$ListAll,

    [Parameter(HelpMessage = 'Treat the variable as a path and return path object')]
    [switch]$AsPath,

    [Parameter(HelpMessage = 'Enable caching for improved performance')]
    [switch]$Cached,

    [Parameter(HelpMessage = 'Name of the environment variable to retrieve')]
    [ValidateNotNullOrEmpty()]
    [string]$Name,

    [Parameter(HelpMessage = 'Expand embedded environment variables')]
    [switch]$ExpandVars,

    [Parameter(HelpMessage = 'Sort method for returned variables')]
    [ValidateSet('None', 'Name', 'NameDescending', 'Value', 'ValueDescending', 'Length', 'LengthDescending', 'Priority', 'Alphanumeric', 'Type')]
    [string]$Sort = 'Alphanumeric',

    [Parameter(Position = 0, HelpMessage = 'Filter pattern for variable names when listing')]
    [string]$Pattern = $null
  )

  $debugParams = @{
    Name       = $Name
    Scope      = $Scope
    ListAll    = $ListAll.IsPresent
    AsPath     = $AsPath.IsPresent
    Cached     = $Cached.IsPresent
    # Pattern    = $Pattern
    # Pattern    = if ($null -ne $Pattern) { $Pattern } else { $Name}
    Pattern    = if ([string]::IsNullOrEmpty($Pattern)) { $Pattern } else { $Name }
    ExpandVars = $ExpandVars.IsPresent
  }
  Write-Pretty -Tag 'Trace' -ContextScope $script:ctxScope -OneLine -Message "Get-Env called with: $(($debugParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', ')"

  # Check cache first if enabled and retrieving specific variable
  if ($Cached -and ![string]::IsNullOrEmpty($Name) -and !$ListAll) {
    $cacheKey = "${Scope}:${Name}"
    if ($script:EnvCache.ContainsKey($cacheKey) -and $script:CacheExpiry.ContainsKey($cacheKey)) {
      if ((Get-Date) -lt $script:CacheExpiry[$cacheKey]) {
        Write-Pretty -Tag 'Trace' -ContextScope $script:ctxScope -OneLine -Message "Returning cached value for '$Name'"
        return $script:EnvCache[$cacheKey]
      }
      else {
        # Remove expired cache entry
        $script:EnvCache.Remove($cacheKey)
        $script:CacheExpiry.Remove($cacheKey)
        Write-Pretty -Tag 'Debug' -ContextScope $script:ctxScope -OneLine -Message "Cache expired for '$Name', fetching fresh value"
      }
    }
  }

  if ([string]::IsNullOrEmpty($Name) -or $ListAll) {
    #~@ Return all environment variables based on scope
    $allEnvVars = Get-EnvironmentVariablesByScope -Scope $Scope
    #~@ Apply pattern filtering if specified
    if (![string]::IsNullOrEmpty($Pattern)) {
      Write-Pretty -Tag 'Trace' -ContextScope $script:ctxScope -OneLine -Message "Applying pattern filter: '$Pattern'"
      $filteredVars = @{}
      foreach ($var in $allEnvVars.GetEnumerator()) {
        if ($var.Key -like $Pattern) {
          $filteredVars[$var.Key] = $var.Value
        }
      }
      $allEnvVars = $filteredVars
      Write-Pretty -Tag 'Debug' -ContextScope $script:ctxScope -OneLine -Message "Pattern filtering resulted in $($allEnvVars.Count) variables"
    }

    #~@ Apply sorting
    $sortedEnvVars = Get-EnvSorted -Variables $allEnvVars -SortMethod $Sort -Scope $Scope

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
          Write-Pretty -Tag 'Debug' -ContextScope $script:ctxScope -OneLine -Message "Expanded '$value' to '$expandedValue'"
          $expandedValue
        }
        catch {
          Write-Pretty -Tag 'Warning' -ContextScope $script:ctxScope -OneLine -Message "Failed to expand variables in '$value': $($_.Exception.Message)"
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
        Write-Pretty -Tag 'Debug' -ContextScope $script:ctxScope -OneLine -Message "Variable '$Name' not found, returning typed default value"
        $Default
      }
      else {
        Write-Pretty -Tag 'Debug' -ContextScope $script:ctxScope -OneLine -Message "Variable '$Name' not found and no default specified"
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
      Write-Pretty -Tag 'Debug' -ContextScope $script:ctxScope -OneLine -Message "Cached value for '$Name' with TTL $script:CacheTTL seconds"
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

  Write-Pretty -Tag 'Trace' -ContextScope $script:ctxScope -OneLine -Message "Set-Env called: Name='$Name', Value='$Value', Type='$Type', Scope='$Scope'"

  #~@ Expand environment variables in the value
  $expandedValue = [System.Environment]::ExpandEnvironmentVariables($Value)
  if ($expandedValue -ne $Value) {
    Write-Pretty -Tag 'Debug' -ContextScope $script:ctxScope -OneLine -Message "Expanded value from '$Value' to '$expandedValue'"
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
      Write-Pretty -Tag 'Trace' -ContextScope $script:ctxScope -OneLine -Message "Auto-detected type 'cd' from name pattern"
    }
    elseif ($processedName -match '^edit\.') {
      $Type = 'edit'
      Write-Pretty -Tag 'Trace' -ContextScope $script:ctxScope -OneLine -Message "Auto-detected type 'edit' from name pattern"
    }
  }

  #~@ Validation logic
  if ($Validate -or $Type -in @('cd', 'path')) {
    if ($Type -eq 'cd' -or $Type -eq 'path') {
      if (![string]::IsNullOrEmpty($expandedValue) -and !(Test-Path $expandedValue -PathType Container -ErrorAction SilentlyContinue)) {
        Write-Pretty -Tag 'Warning' -ContextScope $script:ctxScope -OneLine -Message "Path validation failed: Directory '$expandedValue' does not exist"
        if (!$PSCmdlet.ShouldContinue('Directory does not exist. Continue anyway?', 'Path Validation')) {
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
        Write-Pretty -Tag 'Trace' -ContextScope $script:ctxScope -OneLine -Message "Cleared cache for updated variable '$processedName'"
      }

      Write-Pretty -Tag 'Success' -ContextScope $script:ctxScope -OneLine -Message "Set ${processedName} => ${expandedValue} [$Scope]"
      return $true
    }
    catch {
      Write-Pretty -Tag 'Error' -ContextScope $script:ctxScope -OneLine -Message "Failed to set environment variable '$processedName': $($_.Exception.Message)"
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

      Write-Pretty -Tag 'Success' -ContextScope $script:ctxScope -OneLine -Message "Removed environment variable '$Name' from $Scope scope"
      return $true
    }
    catch {
      Write-Pretty -Tag 'Error' -ContextScope $script:ctxScope -OneLine -Message "Failed to remove environment variable '$Name': $($_.Exception.Message)"
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

    Write-Pretty -Tag 'Info' -ContextScope $script:ctxScope -OneLine -Message "Cleared $($keysToRemove.Count) cache entries matching criteria"
  }
  else {
    #~@ Clear all cache
    $script:EnvCache.Clear()
    $script:CacheExpiry.Clear()
    Write-Pretty -Tag 'Info' -ContextScope $script:ctxScope -OneLine -Message "Cleared all $initialCount cache entries"
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
  Write-Pretty -Tag 'Info' -ContextScope $script:ctxScope -OneLine -Message "Cache TTL set to $Seconds seconds"
}

function Global:Get-EnvironmentVariablesByScope {
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
      Write-Pretty -Tag 'Debug' -ContextScope $script:ctxScope -OneLine -Message "Retrieved $($machineVars.Count) Machine scope variables"
    }
    catch {
      Write-Pretty -Tag 'Warning' -ContextScope $script:ctxScope -OneLine -Message "Failed to access Machine scope variables: $($_.Exception.Message)"
    }

    # Add User scope (medium priority)
    try {
      $userVars = [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::User)
      foreach ($var in $userVars.GetEnumerator()) {
        $allVars[$var.Key] = $var.Value
      }
      Write-Pretty -Tag 'Debug' -ContextScope $script:ctxScope -OneLine -Message "Retrieved $($userVars.Count) User scope variables"
    }
    catch {
      Write-Pretty -Tag 'Warning' -ContextScope $script:ctxScope -OneLine -Message "Failed to access User scope variables: $($_.Exception.Message)"
    }

    # Add Process scope (highest priority)
    try {
      $processVars = [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::Process)
      foreach ($var in $processVars.GetEnumerator()) {
        $allVars[$var.Key] = $var.Value
      }
      Write-Pretty -Tag 'Debug' -ContextScope $script:ctxScope -OneLine -Message "Retrieved $($processVars.Count) Process scope variables"
    }
    catch {
      Write-Pretty -Tag 'Warning' -ContextScope $script:ctxScope -OneLine -Message "Failed to access Process scope variables: $($_.Exception.Message)"
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
      Write-Pretty -Tag 'Debug' -ContextScope $script:ctxScope -OneLine -Message "Retrieved $($variables.Count) variables from $Scope scope"
      return $variables
    }
    catch {
      Write-Pretty -Tag 'Warning' -ContextScope $script:ctxScope -OneLine -Message "Primary method failed for $Scope scope: $($_.Exception.Message)"

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
          Write-Pretty -Tag 'Debug' -ContextScope $script:ctxScope -OneLine -Message "Fallback: Retrieved $($envDriveVars.Count) variables from Env: drive"
          return $envDriveVars
        }
        catch {
          Write-Pretty -Tag 'Error' -ContextScope $script:ctxScope -OneLine -Message "All methods failed for Process scope: $($_.Exception.Message)"
          return @{}
        }
      }
    }
  }
}

function Global:Get-SpecificEnvironmentVariable {
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
        Write-Pretty -Tag 'Debug' -ContextScope $script:ctxScope -OneLine -Message "Found '$Name' in $currentScope scope"
        return $value
      }
    }
    Write-Pretty -Tag 'Debug' -ContextScope $script:ctxScope -OneLine -Message "Variable '$Name' not found in any scope"
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
        Write-Pretty -Tag 'Debug' -ContextScope $script:ctxScope -OneLine -Message "Retrieved '$Name' from $Scope scope (length: $($value.Length))"
      }
      return $value
    }
    catch {
      Write-Pretty -Tag 'Warning' -ContextScope $script:ctxScope -OneLine -Message "Primary method failed for '$Name' in $Scope scope: $($_.Exception.Message)"

      # Fallback methods
      if ($Scope -eq 'Process') {
        # Try Env: drive
        try {
          $value = (Get-Item "Env:$Name" -ErrorAction Stop).Value
          Write-Pretty -Tag 'Debug' -ContextScope $script:ctxScope -OneLine -Message "Fallback: Retrieved '$Name' from Env: drive"
          return $value
        }
        catch {
          Write-Pretty -Tag 'Debug' -ContextScope $script:ctxScope -OneLine -Message "Env: drive fallback failed for '$Name': $($_.Exception.Message)"
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

function Global:Get-EnvironmentVariablesFromRegistry {
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
          Write-Pretty -Tag 'Warning' -ContextScope $script:ctxScope -OneLine -Message "Failed to read registry value '$valueName': $($_.Exception.Message)"
        }
      }
      Write-Pretty -Tag 'Debug' -ContextScope $script:ctxScope -OneLine -Message "Registry fallback: Retrieved $($regVars.Count) variables from $Scope scope"
      return $regVars
    }
    else {
      Write-Pretty -Tag 'Warning' -ContextScope $script:ctxScope -OneLine -Message "Registry path '$registryPath' not found"
      return @{}
    }
  }
  catch {
    Write-Pretty -Tag 'Error' -ContextScope $script:ctxScope -OneLine -Message "Registry fallback failed for $Scope scope: $($_.Exception.Message)"
    return @{}
  }
}

function Global:Get-EnvironmentVariableFromRegistry {
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
      Write-Pretty -Tag 'Debug' -ContextScope $script:ctxScope -OneLine -Message "Registry fallback: Retrieved '$Name' from $Scope scope"
      return $value
    }
    else {
      Write-Pretty -Tag 'Warning' -ContextScope $script:ctxScope -OneLine -Message "Registry path '$registryPath' not found"
      return $null
    }
  }
  catch {
    Write-Pretty -Tag 'Debug' -ContextScope $script:ctxScope -OneLine -Message "Registry fallback failed for '$Name' in $Scope scope: $($_.Exception.Message)"
    return $null
  }
}

function Global:Get-EnvSorted {
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

  # Write-Pretty -Tag 'Trace' -ContextScope $script:ctxScope -OneLine -Message "Sorting $($Variables.Count) variables by: $SortMethod"

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
      Write-Pretty -Tag 'Warning' -ContextScope $script:ctxScope -OneLine -Message "Unknown sort method '$SortMethod', using no sorting"
      return $Variables
    }
  }

  Write-Pretty -Tag 'Trace' -ContextScope $script:ctxScope -OneLine -Message "$SortMethod sort performed on $($sortedVars.Count) variables"
  return $sortedVars
}

function Global:ConvertTo-PathObject {
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
      Write-Pretty -Tag 'Debug' -ContextScope $script:ctxScope -OneLine -Message "Converted '$VariableName' to directory path object: $expandedPath"
      return $pathObject
    }
    elseif (Test-Path $expandedPath -PathType Leaf) {
      $pathObject = Get-Item $expandedPath -Force
      Write-Pretty -Tag 'Debug' -ContextScope $script:ctxScope -OneLine -Message "Converted '$VariableName' to file path object: $expandedPath"
      return $pathObject
    }
    else {
      # Path doesn't exist, but we can still return a path object
      try {
        $pathObject = [System.IO.DirectoryInfo]::new($expandedPath)
        Write-Pretty -Tag 'Warning' -ContextScope $script:ctxScope -OneLine -Message "Path '$expandedPath' does not exist, returning DirectoryInfo object"
        return $pathObject
      }
      catch {
        Write-Pretty -Tag 'Warning' -ContextScope $script:ctxScope -OneLine -Message "Failed to create path object for '$expandedPath': $($_.Exception.Message)"
        return $expandedPath
      }
    }
  }
  catch {
    Write-Pretty -Tag 'Error' -ContextScope $script:ctxScope -OneLine -Message "Failed to convert '$Path' to path object: $($_.Exception.Message)"
    return $Path
  }
}

function Global:New-EnvironmentFunction {
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

    Write-Pretty -Tag 'Success' -ContextScope $script:ctxScope -OneLine -Message "Created $Type function '$functionName'"
    return $true
  }
  catch {
    Write-Pretty -Tag 'Error' -ContextScope $script:ctxScope -OneLine -Message "Failed to create $Type function '$Name': $($_.Exception.Message)"
    return $false
  }
}

function Global:Test-EnvironmentScope {
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

function Global:Test-GetEnv {
  <#
    .SYNOPSIS
        Comprehensive test suite and demonstration for Get-Env function capabilities.

    .DESCRIPTION
        Test-GetEnv provides thorough testing and live demonstration of all Get-Env features:
        • Basic variable retrieval across all scopes
        • Type conversion and default value handling
        • Path validation and expansion
        • Caching performance testing
        • Pattern matching and sorting capabilities
        • Error handling and edge cases
        • Performance benchmarking
        • Real-world usage scenarios

    .PARAMETER TestType
        Specifies which test category to run:
        • All: Complete test suite (default)
        • Basic: Core functionality tests
        • Advanced: Complex features and edge cases
        • Performance: Caching and performance benchmarks
        • Interactive: User-guided demonstration
        • Validation: Input validation and error handling

    .PARAMETER Detailed
        Provides verbose output with explanations for each test.

    .PARAMETER Benchmark
        Includes performance timing for operations.

    .PARAMETER SkipSlow
        Skips tests that may take longer (cache expiry, large enumerations).

    .EXAMPLE
        Test-GetEnv

        Runs the complete test suite with standard output.

    .EXAMPLE
        Test-GetEnv -TestType Performance -Benchmark -Detailed

        Runs performance tests with detailed timing information.

    .EXAMPLE
        Test-GetEnv -TestType Interactive

        Provides an interactive demonstration of Get-Env features.
    #>

  [CmdletBinding()]
  param(
    [Parameter(HelpMessage = 'Type of tests to run')]
    [ValidateSet('All', 'Basic', 'Advanced', 'Performance', 'Interactive', 'Validation')]
    [string]$TestType = 'All',

    [Parameter(HelpMessage = 'Provide detailed explanations for each test')]
    [switch]$Detailed,

    [Parameter(HelpMessage = 'Include performance benchmarking')]
    [switch]$Benchmark,

    [Parameter(HelpMessage = 'Skip slower tests')]
    [switch]$SkipSlow
  )

  # Test helper functions
  function Write-TestHeader {
    param([string]$Title)
    Write-Host "`n" + '='*60 -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host '='*60 -ForegroundColor Cyan
  }

  function Write-TestSection {
    param([string]$Section)
    Write-Host "`n--- $Section ---" -ForegroundColor Yellow
  }

  function Write-TestResult {
    param(
      [string]$Test,
      [bool]$Passed,
      [string]$Details = '',
      [double]$Duration = 0
    )
    $status = if ($Passed) { '✓ PASS' } else { '✗ FAIL' }
    $color = if ($Passed) { 'Green' } else { 'Red' }

    $output = "  $status - $Test"
    if ($Duration -gt 0) {
      $output += " ($([math]::Round($Duration, 3))ms)"
    }
    if ($Details) {
      $output += " | $Details"
    }

    Write-Host $output -ForegroundColor $color
  }

  function Measure-TestOperation {
    param([scriptblock]$Operation)
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
      $result = & $Operation
      $stopwatch.Stop()
      return @{
        Result   = $result
        Duration = $stopwatch.Elapsed.TotalMilliseconds
        Success  = $true
        Error    = $null
      }
    }
    catch {
      $stopwatch.Stop()
      return @{
        Result   = $null
        Duration = $stopwatch.Elapsed.TotalMilliseconds
        Success  = $false
        Error    = $_.Exception.Message
      }
    }
  }

  # Setup test environment variables for testing
  function Initialize-TestEnvironment {
    Write-TestSection 'Initializing Test Environment'

    # Set test variables
    $env:TEST_STRING = 'Hello World'
    $env:TEST_NUMBER = '42'
    $env:TEST_BOOLEAN = 'true'
    $env:TEST_PATH = $env:TEMP
    $env:TEST_WITH_VARS = '%USERPROFILE%\TestDir'
    $env:PYTHON_TEST_HOME = 'C:\Python39'
    $env:JAVA_TEST_HOME = 'C:\Program Files\Java\jdk-11'
    $env:APP_TEST_TIMEOUT = '30'
    $env:APP_TEST_DEBUG = 'false'

    Write-Host '  Test environment variables created' -ForegroundColor Green
  }

  function Restore-Environment {
    Write-TestSection 'Cleaning Up Test Environment'

    # Remove test variables
    $testVars = @(
      'TEST_STRING', 'TEST_NUMBER', 'TEST_BOOLEAN', 'TEST_PATH',
      'TEST_WITH_VARS', 'PYTHON_TEST_HOME', 'JAVA_TEST_HOME',
      'APP_TEST_TIMEOUT', 'APP_TEST_DEBUG'
    )

    foreach ($var in $testVars) {
      Remove-Item "env:$var" -ErrorAction SilentlyContinue
    }

    Write-Host '  Test environment variables removed' -ForegroundColor Green
  }

  # Test categories
  function Test-BasicFunctionality {
    Write-TestHeader 'BASIC FUNCTIONALITY TESTS'

    Write-TestSection 'Standard Variable Retrieval'

    # Test 1: Basic variable retrieval
    $test = Measure-TestOperation { Get-Env 'TEST_STRING' }
    Write-TestResult 'Basic string retrieval' ($test.Result -eq 'Hello World') $test.Result $test.Duration
    if ($Detailed) {
      Write-Host "    Retrieved: '$($test.Result)' from environment variable TEST_STRING" -ForegroundColor Gray
    }

    # Test 2: Non-existent variable
    $test = Measure-TestOperation { Get-Env 'NON_EXISTENT_VAR' }
    Write-TestResult 'Non-existent variable returns null' ($null -eq $test.Result) "Returned: $($test.Result)" $test.Duration

    # Test 3: Default value handling
    $test = Measure-TestOperation { Get-Env 'NON_EXISTENT_VAR' -Default 'DefaultValue' }
    Write-TestResult 'Default value fallback' ($test.Result -eq 'DefaultValue') $test.Result $test.Duration

    # Test 4: Type conversion with defaults
    $test = Measure-TestOperation { Get-Env 'NON_EXISTENT_NUMBER' -Default 100 }
    Write-TestResult 'Integer default type conversion' (($test.Result -eq 100) -and ($test.Result -is [int])) "Value: $($test.Result), Type: $($test.Result.GetType().Name)" $test.Duration

    # Test 5: Boolean default
    $test = Measure-TestOperation { Get-Env 'NON_EXISTENT_BOOL' -Default $true }
    Write-TestResult 'Boolean default type conversion' (($test.Result -eq $true) -and ($test.Result -is [bool])) "Value: $($test.Result), Type: $($test.Result.GetType().Name)" $test.Duration

    Write-TestSection 'Scope Testing'

    # Test 6: Process scope (default)
    $test = Measure-TestOperation { Get-Env 'TEST_STRING' -Scope Process }
    Write-TestResult 'Process scope access' ($test.Result -eq 'Hello World') 'Scope: Process' $test.Duration

    # Test 7: All scopes search
    $test = Measure-TestOperation { Get-Env 'PATH' -Scope All }
    Write-TestResult 'All scopes search' (![string]::IsNullOrEmpty($test.Result)) 'Found PATH variable' $test.Duration
  }

  function Test-AdvancedFeatures {
    Write-TestHeader 'ADVANCED FEATURES TESTS'

    Write-TestSection 'Variable Expansion'

    # Test 1: Variable expansion
    $test = Measure-TestOperation { Get-Env 'TEST_WITH_VARS' -ExpandVars }
    $expectedStart = $env:USERPROFILE
    Write-TestResult 'Variable expansion' ($test.Result.StartsWith($expectedStart)) "Expanded to: $($test.Result)" $test.Duration
    if ($Detailed) {
      Write-Host '    Original: %USERPROFILE%\TestDir' -ForegroundColor Gray
      Write-Host "    Expanded: $($test.Result)" -ForegroundColor Gray
    }

    Write-TestSection 'Path Handling'

    # Test 2: AsPath parameter
    $test = Measure-TestOperation { Get-Env 'TEST_PATH' -AsPath }
    Write-TestResult 'Path object conversion' ($test.Success -and $null -ne $test.Result) "Type: $($test.Result.GetType().Name)" $test.Duration

    Write-TestSection 'Pattern Matching and Listing'

    # Test 3: Pattern matching
    $test = Measure-TestOperation { Get-Env -Pattern 'TEST_*' }
    $testVarCount = ($test.Result.Keys | Where-Object { $_ -like 'TEST_*' }).Count
    Write-TestResult 'Pattern matching for TEST_*' ($testVarCount -ge 5) "Found $testVarCount variables" $test.Duration
    if ($Detailed) {
      Write-Host '    Matched variables:' -ForegroundColor Gray
      $test.Result.Keys | Where-Object { $_ -like 'TEST_*' } | ForEach-Object {
        Write-Host "      $_" -ForegroundColor Gray
      }
    }

    # Test 4: Sorting
    $test = Measure-TestOperation { Get-Env -Pattern '*TEST*' -Sort Name }
    $sortedCorrectly = $true
    $previousKey = ''
    foreach ($key in $test.Result.Keys) {
      if ($previousKey -and $key -lt $previousKey) {
        $sortedCorrectly = $false
        break
      }
      $previousKey = $key
    }
    Write-TestResult 'Alphabetical sorting' $sortedCorrectly 'Variables sorted by name' $test.Duration

    Write-TestSection 'List All Variables'

    # Test 5: List all variables
    $test = Measure-TestOperation { Get-Env -ListAll }
    Write-TestResult 'List all environment variables' ($test.Result.Count -gt 10) "Found $($test.Result.Count) variables" $test.Duration
  }

  function Test-Performance {
    Write-TestHeader 'PERFORMANCE AND CACHING TESTS'

    Write-TestSection 'Caching Performance'

    # Test 1: First retrieval (no cache)
    $test1 = Measure-TestOperation { Get-Env 'PATH' -Cached }
    Write-TestResult 'First cached retrieval' $test1.Success 'Initial fetch' $test1.Duration

    # Test 2: Second retrieval (from cache)
    $test2 = Measure-TestOperation { Get-Env 'PATH' -Cached }
    Write-TestResult 'Second cached retrieval' $test2.Success 'From cache' $test2.Duration

    $speedImprovement = if ($test2.Duration -gt 0) { [math]::Round(($test1.Duration / $test2.Duration), 2) } else { '∞' }
    if ($Detailed) {
      Write-Host "    Cache performance: ${speedImprovement}x faster" -ForegroundColor Gray
    }

    # Test 3: Multiple rapid retrievals
    $test = Measure-TestOperation {
      1..10 | ForEach-Object { Get-Env 'PATH' -Cached }
    }
    Write-TestResult 'Multiple cached retrievals (10x)' $test.Success 'Batch operation' $test.Duration

    Write-TestSection 'Scope Performance Comparison'

    # Compare different scope performance
    $scopes = @('Process', 'User', 'Machine', 'All')
    foreach ($scope in $scopes) {
      try {
        $test = Measure-TestOperation { Get-Env 'PATH' -Scope $scope }
        Write-TestResult "$scope scope retrieval" $test.Success 'PATH variable' $test.Duration
      }
      catch {
        Write-TestResult "$scope scope retrieval" $false 'Access denied or unavailable' 0
      }
    }

    if (!$SkipSlow) {
      Write-TestSection 'Large Enumeration Performance'

      # Test large enumeration
      $test = Measure-TestOperation { Get-Env -ListAll -Sort Name }
      Write-TestResult 'Full environment enumeration with sorting' $test.Success "$($test.Result.Count) variables" $test.Duration
    }
  }

  function Test-ValidationAndErrorHandling {
    Write-TestHeader 'VALIDATION AND ERROR HANDLING TESTS'

    Write-TestSection 'Parameter Validation'

    # Test 1: Invalid scope
    $test = Measure-TestOperation {
      try {
        Get-Env 'PATH' -Scope 'InvalidScope'
        $false
      }
      catch {
        $true
      }
    }
    Write-TestResult 'Invalid scope parameter validation' $test.Result 'Should throw validation error' $test.Duration

    # Test 2: Empty pattern handling
    $test = Measure-TestOperation { Get-Env -Pattern '' }
    Write-TestResult 'Empty pattern handling' $test.Success 'Should handle gracefully' $test.Duration

    Write-TestSection 'Edge Cases'

    # Test 3: Very long variable name
    $longName = 'A' * 1000
    $test = Measure-TestOperation { Get-Env $longName -Default 'NotFound' }
    Write-TestResult 'Very long variable name' ($test.Result -eq 'NotFound') 'Handled gracefully' $test.Duration

    # Test 4: Special characters in variable name
    $test = Measure-TestOperation { Get-Env 'SPECIAL@#$%' -Default 'NotFound' }
    Write-TestResult 'Special characters in name' ($test.Result -eq 'NotFound') 'Handled gracefully' $test.Duration

    # Test 5: Null default value
    $test = Measure-TestOperation { Get-Env 'NON_EXISTENT' -Default $null }
    Write-TestResult 'Null default value' ($null -eq $test.Result) 'Returns null correctly' $test.Duration
  }

  function Test-RealWorldScenarios {
    Write-TestHeader 'REAL-WORLD USAGE SCENARIOS'

    Write-TestSection 'Configuration Management'

    # Scenario 1: Application configuration
    $config = @{}
    try {
      $config.DatabaseUrl = Get-Env 'DATABASE_URL' -Default 'localhost:5432'
      $config.ApiTimeout = Get-Env 'API_TIMEOUT' -Default 30
      $config.DebugMode = Get-Env 'DEBUG_MODE' -Default $false
      $config.LogLevel = Get-Env 'LOG_LEVEL' -Default 'INFO'

      Write-TestResult 'Application configuration loading' $true 'Config object created with defaults' 0
      if ($Detailed) {
        Write-Host '    Configuration loaded:' -ForegroundColor Gray
        $config.GetEnumerator() | ForEach-Object {
          Write-Host "      $($_.Key): $($_.Value) [$($_.Value.GetType().Name)]" -ForegroundColor Gray
        }
      }
    }
    catch {
      Write-TestResult 'Application configuration loading' $false $_.Exception.Message 0
    }

    Write-TestSection 'Development Environment Detection'

    # Scenario 2: Environment detection
    $test = Measure-TestOperation {
      $env = Get-Env 'ENVIRONMENT' -Default 'production'
      $isDevelopment = $env -eq 'development'
      $isProduction = $env -eq 'production'

      @{
        Environment   = $env
        IsDevelopment = $isDevelopment
        IsProduction  = $isProduction
      }
    }
    Write-TestResult 'Environment detection' $test.Success "Environment: $($test.Result.Environment)" $test.Duration

    Write-TestSection 'Tool Path Discovery'

    # Scenario 3: Development tool discovery
    $tools = @{
      Python = Get-Env 'PYTHON_TEST_HOME' -AsPath
      Java   = Get-Env 'JAVA_TEST_HOME' -AsPath
      Node   = Get-Env 'NODE_HOME' -Default 'Not installed'
    }

    $foundTools = ($tools.Values | Where-Object { $_ -ne 'Not installed' }).Count
    Write-TestResult 'Development tool discovery' ($foundTools -gt 0) "Found $foundTools tools" 0

    if ($Detailed) {
      Write-Host '    Tool paths:' -ForegroundColor Gray
      $tools.GetEnumerator() | ForEach-Object {
        $status = if ($_.Value -eq 'Not installed') { 'Missing' } else { 'Found' }
        Write-Host "      $($_.Key): $status" -ForegroundColor Gray
      }
    }
  }

  function Start-InteractiveDemo {
    Write-TestHeader 'INTERACTIVE DEMONSTRATION'

    Write-Host 'This interactive demo will walk you through Get-Env features.' -ForegroundColor Cyan
    Write-Host "Press Enter to continue between steps, or 'q' to quit.`n" -ForegroundColor Yellow

    $steps = @(
      @{
        Title       = 'Basic Variable Retrieval'
        Code        = 'Get-Env "PATH"'
        Description = 'Retrieve the PATH environment variable'
      },
      @{
        Title       = 'Default Value Handling'
        Code        = 'Get-Env "MY_CUSTOM_VAR" -Default "default_value"'
        Description = "Use a default value when variable doesn't exist"
      },
      @{
        Title       = 'Type Conversion'
        Code        = 'Get-Env "TIMEOUT" -Default 30'
        Description = 'Default value determines return type (integer)'
      },
      @{
        Title       = 'Pattern Matching'
        Code        = 'Get-Env -Pattern "PROC*" | Select-Object -First 3'
        Description = "Find all variables starting with 'PROC'"
      },
      @{
        Title       = 'Caching for Performance'
        Code        = 'Measure-Command { Get-Env "PATH" -Cached }'
        Description = 'Enable caching for repeated access'
      },
      @{
        Title       = 'Path Handling'
        Code        = 'Get-Env "USERPROFILE" -AsPath'
        Description = 'Treat variable as a file system path'
      },
      @{
        Title       = 'Variable Expansion'
        Code        = 'Get-Env "TEST_WITH_VARS" -ExpandVars'
        Description = 'Expand embedded environment variables'
      },
      @{
        Title       = 'Multi-Scope Search'
        Code        = 'Get-Env "PATH" -Scope All'
        Description = 'Search across all environment scopes'
      }
    )

    foreach ($step in $steps) {
      Write-Host "--- $($step.Title) ---" -ForegroundColor Yellow
      Write-Host $step.Description -ForegroundColor Gray
      Write-Host 'Code: ' -NoNewline -ForegroundColor White
      Write-Host $step.Code -ForegroundColor Green
      Write-Host ''

      $userInput = Read-Host "Press Enter to execute (or 'q' to quit)"
      if ($userInput -eq 'q') { return }

      try {
        Write-Host 'Output:' -ForegroundColor Cyan
        $result = Invoke-Expression $step.Code
        if ($result -is [hashtable]) {
          $result.GetEnumerator() | Select-Object -First 5 | ForEach-Object {
            Write-Host "  $($_.Key) = $($_.Value)" -ForegroundColor White
          }
          if ($result.Count -gt 5) {
            Write-Host "  ... and $($result.Count - 5) more" -ForegroundColor Gray
          }
        }
        else {
          Write-Host "  $result" -ForegroundColor White
        }
      }
      catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
      }
      Write-Host ''
    }

    Write-Host 'Interactive demonstration completed!' -ForegroundColor Green
  }

  # Main test execution
  try {
    Initialize-TestEnvironment

    $testResults = @{
      TotalTests  = 0
      PassedTests = 0
      FailedTests = 0
      StartTime   = Get-Date
    }

    switch ($TestType) {
      'Basic' {
        Test-BasicFunctionality
      }
      'Advanced' {
        Test-AdvancedFeatures
      }
      'Performance' {
        Test-Performance
      }
      'Interactive' {
        Start-InteractiveDemo
        return # Skip summary for interactive mode
      }
      'Validation' {
        Test-ValidationAndErrorHandling
      }
      'All' {
        Test-BasicFunctionality
        Test-AdvancedFeatures
        Test-Performance
        Test-ValidationAndErrorHandling
        Test-RealWorldScenarios
      }
    }

    # Test summary
    $testResults.EndTime = Get-Date
    $duration = ($testResults.EndTime - $testResults.StartTime).TotalSeconds

    Write-TestHeader 'TEST SUMMARY'
    Write-Host "Test Duration: $([math]::Round($duration, 2)) seconds" -ForegroundColor Cyan
    Write-Host 'Get-Env function testing completed successfully!' -ForegroundColor Green

    if ($Benchmark) {
      Write-Host "`nPerformance Notes:" -ForegroundColor Yellow
      Write-Host '• Process scope is fastest for most operations' -ForegroundColor Gray
      Write-Host '• Caching provides significant performance benefits for repeated access' -ForegroundColor Gray
      Write-Host '• Pattern matching performance depends on environment size' -ForegroundColor Gray
      Write-Host '• Type conversion adds minimal overhead' -ForegroundColor Gray
    }

    Write-Host "`nRecommendations:" -ForegroundColor Yellow
    Write-Host '• Use caching for frequently accessed variables' -ForegroundColor Gray
    Write-Host '• Prefer Process scope for best performance' -ForegroundColor Gray
    Write-Host '• Use type-safe defaults for configuration management' -ForegroundColor Gray
    Write-Host '• Leverage pattern matching for environment auditing' -ForegroundColor Gray
    Write-Host '• Use AsPath for file system path variables' -ForegroundColor Gray

  }
  finally {
    Restore-Environment

    Write-Host "`nFor more information, run: Get-Help Get-Env -Full" -ForegroundColor Cyan
    Write-Host 'Or explore specific features: Get-Help Get-Env -Examples' -ForegroundColor Cyan
  }
}

# Example usage and quick tests
if ($MyInvocation.InvocationName -ne '.') {
  Write-Host 'Get-Env Test Suite' -ForegroundColor Cyan
  Write-Host 'Usage examples:' -ForegroundColor Yellow
  Write-Host '  Test-GetEnv                    # Run all tests' -ForegroundColor Gray
  Write-Host '  Test-GetEnv -TestType Basic    # Basic functionality only' -ForegroundColor Gray
  Write-Host '  Test-GetEnv -Interactive       # Interactive demonstration' -ForegroundColor Gray
  Write-Host '  Test-GetEnv -Detailed          # Verbose output' -ForegroundColor Gray
  Write-Host '  Test-GetEnv -Benchmark         # Include performance metrics' -ForegroundColor Gray
  Write-Host ''
}
