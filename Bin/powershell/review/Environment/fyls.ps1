#!/usr/bin/env pwsh
#Bin/powershell/environment/fyls.psm1
# PowerShell port of fyls - ls wrapper that tries eza, then lsd, then falls back to ls/Get-ChildItem

#region Global Functions
function Invoke-Fyls {
  <#
    .SYNOPSIS
        A cross-platform ls wrapper that tries eza, then lsd, then falls back to native ls.
    .DESCRIPTION
        Fyls is a flexible directory listing tool that automatically detects and uses the best
        available listing command (eza, lsd, ls, or PowerShell's Get-ChildItem) based on what's
        installed on your system. It provides a unified interface with consistent options across
        all platforms.
    .PARAMETER Tool
        Force specific tool to use (eza, lsd, ls, powershell).
    .PARAMETER All
        Show hidden files and directories.
    .PARAMETER Color
        Force color output.
    .PARAMETER NoColor
        Disable color output.
    .PARAMETER DirFirst
        Show directories first in listings.
    .PARAMETER DirLast
        Show directories last in listings.
    .PARAMETER NoGroup
        Don't group directories.
    .PARAMETER Depth
        Limit recursion depth to specified number.
    .PARAMETER DirectoryOnly
        Show only directories.
    .PARAMETER Git
        Show git status information.
    .PARAMETER NoGit
        Disable git status information.
    .PARAMETER GitIgnore
        Respect .gitignore files when listing.
    .PARAMETER Header
        Show column headers in output.
    .PARAMETER Hyperlink
        Enable hyperlinks in output.
    .PARAMETER NoHyperlink
        Disable hyperlinks in output.
    .PARAMETER Icons
        Show file type icons.
    .PARAMETER NoIcons
        Disable file type icons.
    .PARAMETER Long
        Use long format listing.
    .PARAMETER Link
        Show only symbolic links.
    .PARAMETER Octal
        Show octal permissions.
    .PARAMETER Pagination
        Enable pagination of output.
    .PARAMETER Pretty
        Enable both colors and icons for attractive output.
    .PARAMETER Permission
        Permission format: attributes, rwx, octal, or none.
    .PARAMETER Recursive
        Recursive listing (flat format).
    .PARAMETER Sort
        Sort field: size, time, version, extension, git, none, or name.
    .PARAMETER SortSize
        Sort by file size.
    .PARAMETER SortNone
        Disable sorting.
    .PARAMETER SortTime
        Sort by modification time.
    .PARAMETER SortVersion
        Sort by version numbers in filenames.
    .PARAMETER SortExtension
        Sort by file extension.
    .PARAMETER Tree
        Display output in tree format.
    .PARAMETER ShowCommand
        Show the command that would be executed without running it.
    .PARAMETER Path
        Paths to list. Defaults to current directory if not specified.
    #>
  [CmdletBinding()]
  param(
    [Parameter()]
    [ValidateSet('eza', 'lsd', 'ls', 'powershell')]
    [string]$Tool,

    [Alias('a')]
    [Parameter()]
    [switch]$All,

    [Alias('c')]
    [Parameter()]
    [switch]$Color,

    [Parameter()]
    [switch]$NoColor,

    [Parameter()]
    [switch]$DirFirst,

    [Parameter()]
    [switch]$DirLast,

    [Parameter()]
    [switch]$NoGroup,

    [Alias('n')]
    [Parameter()]
    [ValidateRange(1, 20)]
    [int]$Depth,

    [Alias('D')]
    [Parameter()]
    [switch]$DirectoryOnly,

    [Alias('g')]
    [Parameter()]
    [switch]$Git,

    [Parameter()]
    [switch]$NoGit,

    [Alias('I')]
    [Parameter()]
    [switch]$GitIgnore,

    [Parameter()]
    [switch]$Header,

    [Alias('H')]
    [Parameter()]
    [switch]$Hyperlink,

    [Parameter()]
    [switch]$NoHyperlink,

    [Parameter()]
    [switch]$Icons,

    [Parameter()]
    [switch]$NoIcons,

    [Alias('l')]
    [Parameter()]
    [switch]$Long,

    [Alias('sym', 'symlink')]
    [Parameter()]
    [switch]$Link,

    [Alias('o')]
    [Parameter()]
    [switch]$Octal,

    [Alias('page', 'bat', 'more', 'less')]
    [Parameter()]
    [switch]$Pagination,

    [Alias('P')]
    [Parameter()]
    [switch]$Pretty,

    [Parameter()]
    [ValidateSet('attributes', 'rwx', 'octal', 'none')]
    [string]$Permission = 'none',

    [Alias('R')]
    [Parameter()]
    [switch]$Recursive,

    [Parameter()]
    [ValidateSet('size', 'time', 'version', 'extension', 'git', 'mane', 'none')]
    [string]$Sort = 'name',

    [Alias('S')]
    [Parameter()]
    [switch]$SortSize,

    [Parameter()]
    [switch]$SortNone,

    [Alias('T')]
    [Parameter()]
    [switch]$SortTime,

    [Alias('V')]
    [Parameter()]
    [switch]$SortVersion,

    [Alias('X')]
    [Parameter()]
    [switch]$SortExtension,

    [Parameter()]
    [switch]$Tree,

    [Alias('simulate', 'dry', 'dryrun')]
    [Parameter()]
    [switch]$ShowCommand,

    [Parameter(ValueFromRemainingArguments = $true, Position = 0)]
    [string[]]$Path = @('.')
  )

  Write-Verbose 'Fyls: Starting directory listing operation'
  Write-Debug "Fyls: Parameters - Tool='$Tool', Pretty=$Pretty, Long=$Long, All=$All"

  #~@ Initialize configuration
  $config = Initialize-FylsConfig -Parameters $PSBoundParameters

  #~@ Resolve sort preferences
  $config = Resolve-SortPreferences -Config $config

  #~@ Resolve display preferences
  $config = Resolve-DisplayPreferences -Config $config

  #~@ Determine which tool to use
  $toolCommand = Get-BestAvailableTool -ForcedTool $Tool

  if (-not $toolCommand.Found) {
    Write-Warning 'Fyls: No suitable listing tool found. Please install eza, lsd, or ensure ls/Get-ChildItem is available.'
    return
  }

  Write-Verbose "Fyls: Using tool '$($toolCommand.Name)' at '$($toolCommand.Path)'"


  #~@ Resolve paths
  $resolvedPaths = @()
  foreach ($path in $Path) {
    $resolvedPath = Resolve-PathSafely -NoClobber -Path $path
    if ($resolvedPath) {
      $resolvedPaths += $resolvedPath
    } else {
      Write-Pretty -Tag 'Warn' -NoNewLine -ContextScope Name `
        "No path provided for listing"
      return
    }
    # Write-Host "TEST: path: $path"
    # Write-Host "TEST: resolved: $resolvedPath"
    # $resolvedPaths += $resolvedPath
  }

  #~@ Build command based on selected tool
  $command = Build-Command -Tool $toolCommand -Config $config -Paths $resolvedPaths

  #~@ Add pagination if requested
  if ($config.Pagination) {
    $command = Add-Pagination -Command $command
  }

  #~@ Execute or show command
  if ($ShowCommand) {
    Write-Host "Command: $command" -ForegroundColor Yellow
    return $command
  }
  else {
    try {
      Write-Pretty -Tag 'Error' -NoNewLine -ContextScope Name `
        "Executing command`n  $command"
      # Write-Verbose "Fyls: Executing command - $command"

      if ($command.StartsWith('Get-ChildItem')) {
        Invoke-Expression $command
      }
      else {
        #~@ Use cmd.exe for external commands to handle argument parsing properly
        $escapedCommand = Format-WindowsPathForCmd $command
        cmd /c $escapedCommand
      }
    }
    catch {
      Write-Pretty -Tag 'Error' -NoNewLine `
        "Failed to execute command`n  $command`n  $($_.Exception.Message)"
    }
  }
}
function Invoke-Fyll {
  <#
    .SYNOPSIS
        An alias for Invoke-Fyls with common long listing options.
    .DESCRIPTION
        This function calls Invoke-Fyls with -DirFirst, -Icons, -Git, -All, and -Long by default.
        Any additional parameters passed to 'll' will be forwarded to Invoke-Fyls.
    .EXAMPLE
        ll
        ll -Depth 2
    #>
  [CmdletBinding(DefaultParameterSetName = 'Default')]
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArguments
  )

  Invoke-Fyls -DirFirst -Icons -Git -All -Long -Octal @RemainingArguments
}
function Invoke-Fylt {
  <#
    .SYNOPSIS
        An alias for Invoke-Fyls with common long listing options.
    .DESCRIPTION
        This function calls Invoke-Fyls with -DirFirst, -Icons, -Git, -All, and -Long by default.
        Any additional parameters passed to 'll' will be forwarded to Invoke-Fyls.
    .EXAMPLE
        ll
        ll -Depth 2
    #>
  [CmdletBinding(DefaultParameterSetName = 'Default')]
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArguments
  )

  Invoke-Fyls -DirFirst -Icons -Git -GitIgnore -Tree -All -Long @RemainingArguments
}

#endregion

#region Local Functions
function Initialize-FylsConfig {
  <#
    .SYNOPSIS
        Initialize the configuration object from parameters.
    #>
  [CmdletBinding()]
  param(
    [hashtable]$Parameters
  )

  $config = @{
    All           = $Parameters.All
    Color         = if ($Parameters.NoColor) { $false } else { $Parameters.Color -or $true }
    Depth         = if ($Parameters.Depth) { $Parameters.Depth } else { if ($Parameters.Tree) { 5 } else { 0 } }
    Git           = if ($Parameters.NoGit) { $false } else { $Parameters.Git -or $true }
    GitIgnore     = $Parameters.GitIgnore
    Header        = $Parameters.Header
    Hyperlink     = if ($Parameters.NoHyperlink) { $false } else { $Parameters.Hyperlink -or $true }
    Icons         = if ($Parameters.NoIcons -or $Parameters.Pagination) { $false } else { $Parameters.Icons -or $true }
    Long          = $Parameters.Long
    Octal         = if (-not($Parameters.Long -or $Parameters.Tree)) { $false } else { $Parameters.Octal }
    Pagination    = $Parameters.Pagination
    Permission    = if (-not($Parameters.Long -or $Parameters.Tree)) { $false } else { $Parameters.Permission }
    Recursive     = $Parameters.Recursive
    Tree          = $Parameters.Tree
    Priority      = 'directories'  # Default
    Target        = 'all'           # Default
    RecursionMode = 'none'   # Default
    sort          = $Parameters.Sort
  }

  #~@ Handle Pretty flag
  if ($Parameters.Pretty) {
    $config.Color = $true
    $config.Icons = $true
  }

  #~@ Handle directory grouping
  if ($Parameters.DirFirst) { $config.Priority = 'directories' }
  if ($Parameters.DirLast) { $config.Priority = 'files' }
  if ($Parameters.NoGroup) { $config.Priority = 'none' }

  #~@ Handle target filtering
  if ($Parameters.DirectoryOnly) { $config.Target = 'directory' }
  if ($Parameters.Link) { $config.Target = 'link' }

  #~@ Handle recursion mode
  if ($Parameters.Recursive) { $config.RecursionMode = 'flat' }
  if ($Parameters.Tree) { $config.RecursionMode = 'tree' }

  return $config
}

function Resolve-SortPreferences {
  <#
    .SYNOPSIS
        Resolve sort preferences from multiple parameters.
    #>
  [CmdletBinding()]
  param(
    [hashtable]$Config
  )

  #~@ Sort flags override the Sort parameter
  if (-not $Config.Sort) { $Config.Sort = 'name' }
  if ($PSBoundParameters.ContainsKey('SortSize')) { $Config.Sort = 'size' }
  if ($PSBoundParameters.ContainsKey('SortTime')) { $Config.Sort = 'time' }
  if ($PSBoundParameters.ContainsKey('SortVersion')) { $Config.Sort = 'version' }
  if ($PSBoundParameters.ContainsKey('SortExtension')) { $Config.Sort = 'extension' }
  if ($PSBoundParameters.ContainsKey('SortNone')) { $Config.Sort = 'none' }

  return $Config
}

function Resolve-DisplayPreferences {
  <#
    .SYNOPSIS
        Resolve display preferences and handle conflicts.
    #>
  [CmdletBinding()]
  param(
    [hashtable]$Config
  )

  #~@ Auto-enable recursion if depth is specified
  if ($Config.Depth -gt 0 -and $Config.RecursionMode -eq 'none') {
    $Config.RecursionMode = 'tree'
    Write-Verbose 'Fyls: Auto-enabled tree mode due to depth specification'
  }

  #~@ Handle octal permission preference
  if ($Config.Octal) {
    $Config.Permission = 'octal'
  }

  return $Config
}

function Get-BestAvailableTool {
  <#
    .SYNOPSIS
        Determine the best available listing tool.
    #>
  [CmdletBinding()]
  param(
    [string]$ForcedTool
  )

  if ($ForcedTool) {
    $tool = Test-ToolAvailability -ToolName $ForcedTool
    if ($tool.Found) {
      return $tool
    }
    else {
      Write-Warning "Fyls: Forced tool '$ForcedTool' not found, falling back to auto-detection"
    }
  }

  #~@ Try tools in order of preference
  $toolsToTry = @('eza', 'lsd', 'ls', 'powershell')

  foreach ($toolName in $toolsToTry) {
    $tool = Test-ToolAvailability -ToolName $toolName
    if ($tool.Found) {
      return $tool
    }
  }

  return @{ Found = $false; Name = 'none'; Path = '' }
}

function Test-ToolAvailability {
  <#
    .SYNOPSIS
        Test if a specific tool is available.
    #>
  [CmdletBinding()]
  param(
    [string]$ToolName
  )

  switch ($ToolName) {
    'eza' {
      $envPath = [Environment]::GetEnvironmentVariable('CMD_EZA')
      if ($envPath -and (Test-Path $envPath)) {
        return @{ Found = $true; Name = 'eza'; Path = $envPath }
      }
      $cmd = Get-Command 'eza' -ErrorAction SilentlyContinue
      if ($cmd) {
        # return @{ Found = $true; Name = 'eza'; Path = $cmd.Source }
        return @{ Found = $true; Name = 'eza'; Path = $cmd }
      }
    }
    'lsd' {
      $envPath = [Environment]::GetEnvironmentVariable('CMD_LSD')
      if ($envPath -and (Test-Path $envPath)) {
        return @{ Found = $true; Name = 'lsd'; Path = $envPath }
      }
      $cmd = Get-Command 'lsd' -ErrorAction SilentlyContinue
      if ($cmd) {
        # return @{ Found = $true; Name = 'lsd'; Path = $cmd.Source }
        return @{ Found = $true; Name = 'lsd'; Path = $cmd }
      }
    }
    'powershell' {
      return @{ Found = $true; Name = 'powershell'; Path = 'Get-ChildItem' }
    }
  }

  return @{ Found = $false; Name = $ToolName; Path = '' }
}

function Build-Command {
  <#
    .SYNOPSIS
        Build the appropriate command based on the selected tool and configuration.
    #>
  [CmdletBinding()]
  param(
    [hashtable]$Tool,
    [hashtable]$Config,
    [string[]]$Paths
  )


  switch ($Tool.Name) {
    'eza' { return Build-EzaCommand -Tool $Tool -Config $Config -Paths $Paths }
    'lsd' { return Build-LsdCommand -Tool $Tool -Config $Config -Paths $Paths }
    'ls' { return Build-LsCommand -Tool $Tool -Config $Config -Paths $Paths }
    'powershell' { return Build-PowerShellCommand -Tool $Tool -Config $Config -Paths $Paths }
    default { throw "Unknown tool: $($Tool.Name)" }
  }
}

function Build-EzaCommand {
  <#
    .SYNOPSIS
        Build eza command with appropriate options.
    #>
  [CmdletBinding()]
  param(
    [hashtable]$Tool,
    [hashtable]$Config,
    [string[]]$Paths
  )

  $options = @($Tool.Path)

  if ($Config.All) { $options += '--almost-all' }
  if ($Config.Color) { $options += '--color=always', '--color-scale' }
  if ($Config.Icons) { $options += '--icons=always' }
  if ($Config.Hyperlink) { $options += '--hyperlink' }
  if ($Config.Long) {
    $options += '--long'
    if ($Config.Git) { $options += '--git' }
  }
  if ($Config.GitIgnore) { $options += '--git-ignore' }

  #~@ Priority/grouping
  switch ($Config.Priority) {
    'directories' { $options += '--group-directories-first' }
    'files' { $options += '--group-directories-last' }
  }

  #~@ Permissions
  if ($Config.Permission -or $Config.Octal) {
    switch ($Config.Permission) {
      'none' { $options += '--no-permissions' }
      default { $options += '--octal-permissions' }
    }
  }

  #~@ Target filtering
  switch ($Config.Target) {
    'file' { $options += '--only-files' }
    'directory' { $options += '--only-dirs' }
  }

  #~@ Recursion
  switch ($Config.RecursionMode) {
    'flat' {
      $options += '--recurse'
      if ($Config.Depth -gt 0) { $options += "--level=$($Config.Depth)" }
    }
    'tree' {
      $options += '--tree'
      if ($Config.Depth -gt 0) { $options += "--level=$($Config.Depth)" }
    }
  }

  #~@ Sorting
  if ($Config.Sort -ne 'name') {
    $options += "--sort=$($Config.Sort)"
  }

  $options += $Paths
  return ($options -join ' ')
}

function Build-LsdCommand {
  <#
    .SYNOPSIS
        Build lsd command with appropriate options.
    #>
  [CmdletBinding()]
  param(
    [hashtable]$Tool,
    [hashtable]$Config,
    [string[]]$Paths
  )

  $options = @($Tool.Path)

  if ($Config.All) { $options += '--almost-all' }
  if ($Config.Color) { $options += '--color=always' }
  if ($Config.Icons) { $options += '--icon=always' }
  if ($Config.Hyperlink) { $options += '--hyperlink=always' }
  if ($Config.Long) {
    $options += '--long'
    if ($Config.Git) { $options += '--git' }
  }

  #~@ Priority/grouping
  switch ($Config.Priority) {
    'directories' { $options += '--group-dirs=first' }
    'files' { $options += '--group-dirs=last' }
    'none' { $options += '--group-dirs=none' }
  }

  #~@ Permissions
  if ($Config.Permission -in @('rwx', 'octal', 'attributes')) {
    $options += "--permission=$($Config.Permission)"
  }

  #~@ Target filtering
  switch ($Config.Target) {
    'directory' { $options += '--directory-only' }
    'recursive' { $options += '--recursive' }
  }

  #~@ Recursion
  if ($Config.RecursionMode -eq 'tree') { $options += '--tree' }
  if ($Config.Depth -gt 0 -and ($Config.Target -eq 'recursive' -or $Config.RecursionMode -eq 'tree')) {
    $options += "--depth=$($Config.Depth)"
  }

  #~@ Sorting
  if ($Config.Sort -ne 'name') {
    $options += "--sort=$($Config.Sort)"
  }

  $options += $Paths
  return ($options -join ' ')
}

function Build-LsCommand {
  <#
    .SYNOPSIS
        Build ls command with appropriate options.
    #>
  [CmdletBinding()]
  param(
    [hashtable]$Tool,
    [hashtable]$Config,
    [string[]]$Paths
  )

  $options = @($Tool.Path)

  if ($Config.All) {
    $options += '-la'
  }
  elseif ($Config.Long) {
    $options += '-l'
  }

  if ($Config.Color) { $options += '--color=always' }
  if ($Config.RecursionMode -eq 'flat') { $options += '-R' }
  if ($Config.Target -eq 'directory') { $options += '-d' }

  #~@ Sorting
  switch ($Config.Sort) {
    'size' { $options += '-S' }
    'time' { $options += '-t' }
    'extension' { $options += '-X' }
    'none' { $options += '-U' }
  }

  $options += $Paths
  return ($options -join ' ')
}

function Build-PowerShellCommand {
  <#
    .SYNOPSIS
        Build PowerShell Get-ChildItem command with appropriate options.
    #>
  [CmdletBinding()]
  param(
    [hashtable]$Tool,
    [hashtable]$Config,
    [string[]]$Paths
  )

  $options = @('Get-ChildItem')
  $paths = @($Paths -join ', ')


  if ($Config.All) { $options += '-Force' }
  if ($Config.RecursionMode -eq 'flat') { $options += '-Recurse' }
  if ($Config.Target -eq 'directory') { $options += '-Directory' }
  if ($Config.Depth -gt 0) { $options += '-Depth', $Config.Depth }

  $options += $paths
  return ($options -join ' ')
}

function Add-Pagination {
  <#
    .SYNOPSIS
        Add pagination to the command if requested.
    #>
  [CmdletBinding()]
  param(
    [string]$Command
  )

  $pager = Get-Command 'bat' -ErrorAction SilentlyContinue
  if ($pager) {
    return "$Command | bat --color=always --style=plain"
  }
  else {
    return "$Command | more"
  }
}

#endregion

#region Test
function Test-Fyls {
  <#
    .SYNOPSIS
        Runs diagnostic and feature tests on the Invoke-Fyls function.
    .DESCRIPTION
        Performs comprehensive testing of fyls functionality including tool detection,
        command building, and various parameter combinations.
    .EXAMPLE
        Test-Fyls
    #>
  [CmdletBinding()]
  param()

  $bestTool = Get-BestAvailableTool
  $bestToolTest = if ($bestTool.Found) { Invoke-Fyls -Tool $bestTool.Name -Long -ShowCommand } else { Write-Host 'No best tool found' }
  Write-Pretty -Tag 'Debug' -Scope 'Name' -Delimiter "`n  "`
    "`n~> Simple Parameter Tests <~" `
    'Test 1 | Basic directory listing' `
    "       | $(Invoke-Fyls -ShowCommand)" `
    '       |' `
    'Test 2 | Long format with all files' `
    "       | $(Invoke-Fyls -Long -All -ShowCommand)" `
    '       |' `
    'Test 3 | Pretty output with tree view' `
    "       | $(Invoke-Fyls -Pretty -Tree -Depth 2 -ShowCommand)" `
    '       |' `
    'Test 4 | Directories only, sorted by size <|' `
    "       | $(Invoke-Fyls -DirectoryOnly -SortSize -ShowCommand)" `
    '       |' `
    'Test 5 | Recursive with git status <|' `
    "       | $(Invoke-Fyls -Recursive -Git -ShowCommand)" `
    "`n~> Advanced Parameter Tests <~" `
    'Test 6 | Force specific tool (if available)' `
    "       | $($bestToolTest)" `
    '       |' `
    'Test 7 | Long format with all files' `
    "       | $( Invoke-Fyls -Sort time -Permission octal -Long -ShowCommand)" `
    '       |' `
    'Test 8 | Pretty output with tree view' `
    "       | $(Invoke-Fyls -NoColor -NoIcons -DirFirst -ShowCommand)" `
    "`n~> Tool Availability Tests <~" `
  $(
    $tools = @('eza', 'lsd')
    foreach ($tool in $tools) {
      $result = Test-ToolAvailability -ToolName $tool
      $status = if ($result.Found) { '✓' } else { '✗' }
      "$status $tool" + $(if ($result.Found -and $result.Path) {
          try {
            $result = $result.Path.Source.Replace('\\', '/').Replace('\', '/')
          }
          catch {  }
          " => $($result)`n "
        }
        else { "`n" })
    }
  ) `

  return

  Write-Host "`n=== Configuration Resolution Tests ==="
  Write-Host "`nTesting parameter resolution..."

  $testParams = @{
    Pretty   = $true
    SortTime = $true
    Depth    = 3
    All      = $true
  }

  $config = Initialize-FylsConfig -Parameters $testParams
  $config = Resolve-SortPreferences -Config $config
  $config = Resolve-DisplayPreferences -Config $config

  Write-Host 'Config resolution test:'
  Write-Host "  Sort: $($config.Sort) (should be 'time')"
  Write-Host "  Color: $($config.Color) (should be True)"
  Write-Host "  Icons: $($config.Icons) (should be True)"
  Write-Host "  RecursionMode: $($config.RecursionMode) (should be 'tree')"
}
# Set-Alias -Name fyls -Value Invoke-Fyls
# # Set-Alias -Name ls -Value Invoke-Fyls -Force -Option AllScope
# Set-Alias -Name ll -Value Invoke-Fyls -Force -Option AllScope
#endregion

#region Export

Export-ModuleMember -Function @(
  'Invoke-Fyll',
  'Invoke-Fyls',
  'Invoke-Fylt'
  # 'Test-Fyls'
)

Set-Alias -Name fyls -Value Invoke-Fyls -Scope Global -Force
Set-Alias -Name ll -Value Invoke-Fyll -Scope Global -Force
Set-Alias -Name lt -Value Invoke-Fylt -Scope Global -Force

#endregion
