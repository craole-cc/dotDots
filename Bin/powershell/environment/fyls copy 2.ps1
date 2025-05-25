#!/usr/bin/env pwsh
#Bin/powershell/environment/fyls.psm1
# PowerShell port of fyls - ls wrapper that tries eza, then lsd, then falls back to ls/Get-ChildItem

#region Main
function Get-Children {
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
        # [Alias('t')]
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

        # [Alias('d')]
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

        # [Alias('G')]
        [Parameter()]
        [switch]$Header,

        [Alias('H')]
        [Parameter()]
        [switch]$Hyperlink,

        [Parameter()]
        [switch]$NoHyperlink,

        # [Alias('i')]
        [Parameter()]
        [switch]$Icons,

        [Parameter()]
        [switch]$NoIcons,

        [Alias('l')]
        [Parameter()]
        [switch]$Long,

        [Alias('sym')]
        [Parameter()]
        [switch]$Link,

        [Alias('o')]
        [Parameter()]
        [switch]$Octal,

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
        [ValidateSet('size', 'time', 'version', 'extension', 'git', 'none', 'name')]
        [string]$Sort = 'name',

        [Alias('S')]
        [Parameter()]
        [switch]$SortSize,

        [Alias('N')]
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

    Write-Verbose "Fyls: Starting directory listing operation"
    Write-Debug "Fyls: Parameters - Tool='$Tool', Pretty=$Pretty, Long=$Long, All=$All"

    #@ Initialize configuration
    $config = Initialize-FylsConfig -Parameters $PSBoundParameters

    #@ Resolve sort preferences
    $config = Resolve-SortPreferences -Config $config

    #@ Resolve display preferences
    $config = Resolve-DisplayPreferences -Config $config

    #@ Determine which tool to use
    $toolCommand = Get-BestAvailableTool -ForcedTool $Tool

    if (-not $toolCommand.Found) {
        Write-Warning "Fyls: No suitable listing tool found. Please install eza, lsd, or ensure ls/Get-ChildItem is available."
        return
    }

    Write-Verbose "Fyls: Using tool '$($toolCommand.Name)' at '$($toolCommand.Path)'"

    #@ Build command based on selected tool
    $command = Build-Command -Tool $toolCommand -Config $config -Paths $Path

    #@ Add pagination if requested
    if ($config.Pagination) {
        $command = Add-Pagination -Command $command
    }

    Write-Debug "Fyls: Final command - $command"

    #@ Execute or show command
    if ($ShowCommand) {
        Write-Host "Command: $command" -ForegroundColor Yellow
    }
    else {
        Invoke-Expression -Command $command
        # Invoke-Process $command
        # $command
    }
}

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
        All = $Parameters.All
        Color = if ($Parameters.NoColor) { $false } else { $Parameters.Color -or $true }
        Depth = $Parameters.Depth -or 0
        Git = if ($Parameters.NoGit) { $false } else { $Parameters.Git -or $true }
        GitIgnore = $Parameters.GitIgnore
        Header = $Parameters.Header
        Hyperlink = if ($Parameters.NoHyperlink) { $false } else { $Parameters.Hyperlink -or $true }
        Icons = if ($Parameters.NoIcons) { $false } else { $Parameters.Icons -or $true }
        Long = $Parameters.Long
        Octal = $Parameters.Octal
        Pagination = $Parameters.Pagination
        Permission = $Parameters.Permission
        Recursive = $Parameters.Recursive
        Tree = $Parameters.Tree
        Priority = 'directories'  # Default
        Target = 'all'           # Default
        RecursionMode = 'none'   # Default
        Sort = $Parameters.Sort
    }

    #@ Handle Pretty flag
    if ($Parameters.Pretty) {
        $config.Color = $true
        $config.Icons = $true
    }

    #@ Handle directory grouping
    if ($Parameters.DirFirst) { $config.Priority = 'directories' }
    if ($Parameters.DirLast) { $config.Priority = 'files' }
    if ($Parameters.NoGroup) { $config.Priority = 'none' }

    #@ Handle target filtering
    if ($Parameters.DirectoryOnly) { $config.Target = 'directory' }
    if ($Parameters.Link) { $config.Target = 'link' }

    #@ Handle recursion mode
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

    #@ Sort flags override the Sort parameter
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

    #@ Auto-enable recursion if depth is specified
    if ($Config.Depth -gt 0 -and $Config.RecursionMode -eq 'none') {
        $Config.RecursionMode = 'tree'
        Write-Verbose "Fyls: Auto-enabled tree mode due to depth specification"
    }

    #@ Handle octal permission preference
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

    #@ Try tools in order of preference
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

                Write-Information "Fyls: Found eza at $($cmd)"
                $Global:CMD_EZA = $cmd.Source
                # [Environment]::SetEnvironmentVariable('CMD_EZA', $Global:CMD_EZA, 'Process')
                Set-Item -Path 'env:CMD_EZA' -Value $Global:CMD_EZA
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
                return @{ Found = $true; Name = 'lsd'; Path = $cmd.Source }
            }
        }
        'ls' {
            $envPath = [Environment]::GetEnvironmentVariable('CMD_LS')
            if ($envPath -and (Test-Path $envPath)) {
                return @{ Found = $true; Name = 'ls'; Path = $envPath }
            }
            $cmd = Get-Command 'ls' -ErrorAction SilentlyContinue
            if ($cmd) {
                return @{ Found = $true; Name = 'ls'; Path = $cmd.Source }
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

    $options = @("`"$($Tool.Path)`"")

    if ($Config.All) { $options += '--almost-all' }
    if ($Config.Color) { $options += '--color', 'always', '--color-scale' }
    if ($Config.Icons) { $options += '--icons', 'always' }
    if ($Config.Hyperlink) { $options += '--hyperlink' }
    if ($Config.Long) {
        $options += '--long'
        if ($Config.Git) { $options += '--git' }
    }
    if ($Config.GitIgnore) { $options += '--git-ignore' }

    #@ Priority/grouping
    switch ($Config.Priority) {
        'directories' { $options += '--group-directories-first' }
        'files' { $options += '--group-directories-last' }
    }

    #@ Permissions
    switch ($Config.Permission) {
        'none' { $options += '--no-permissions' }
        default { $options += '--octal-permissions' }
    }

    #@ Target filtering
    switch ($Config.Target) {
        'file' { $options += '--only-files' }
        'directory' { $options += '--only-dirs' }
    }

    #@ Recursion
    switch ($Config.RecursionMode) {
        'flat' {
            $options += '--recurse'
            if ($Config.Depth -gt 0) { $options += '--level', $Config.Depth }
        }
        'tree' {
            $options += '--tree'
            if ($Config.Depth -gt 0) { $options += '--level', $Config.Depth }
        }
    }

    #@ Sorting
    if ($Config.Sort -ne 'name') {
        $options += '--sort', $Config.Sort
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

    $options = @("`"$($Tool.Path)`"")

    if ($Config.All) { $options += '--almost-all' }
    if ($Config.Color) { $options += '--color', 'always' }
    if ($Config.Icons) { $options += '--icon', 'always' }
    if ($Config.Hyperlink) { $options += '--hyperlink', 'always' }
    if ($Config.Long) {
        $options += '--long'
        if ($Config.Git) { $options += '--git' }
    }

    #@ Priority/grouping
    switch ($Config.Priority) {
        'directories' { $options += '--group-dirs', 'first' }
        'files' { $options += '--group-dirs', 'last' }
        'none' { $options += '--group-dirs', 'none' }
    }

    #@ Permissions
    if ($Config.Permission -in @('rwx', 'octal', 'attributes')) {
        $options += '--permission', $Config.Permission
    }

    #@ Target filtering
    switch ($Config.Target) {
        'directory' { $options += '--directory-only' }
        'recursive' { $options += '--recursive' }
    }

    #@ Recursion
    if ($Config.RecursionMode -eq 'tree') { $options += '--tree' }
    if ($Config.Depth -gt 0 -and ($Config.Target -eq 'recursive' -or $Config.RecursionMode -eq 'tree')) {
        $options += '--depth', $Config.Depth
    }

    #@ Sorting
    if ($Config.Sort -ne 'name') {
        $options += '--sort', $Config.Sort
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

    $options = @("`"$($Tool.Path)`"")

    if ($Config.All) {
        $options += '-la'
    } elseif ($Config.Long) {
        $options += '-l'
    }

    if ($Config.Color) { $options += '--color=always' }
    if ($Config.RecursionMode -eq 'flat') { $options += '-R' }
    if ($Config.Target -eq 'directory') { $options += '-d' }

    #@ Sorting
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

    if ($Config.All) { $options += '-Force' }
    if ($Config.RecursionMode -eq 'flat') { $options += '-Recurse' }
    if ($Config.Target -eq 'directory') { $options += '-Directory' }
    if ($Config.Depth -gt 0) { $options += '-Depth', $Config.Depth }

    $options += $Paths
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

function Execute-Command {
    <#
    .SYNOPSIS
        Execute the built command.
    #>
    [CmdletBinding()]
    param(
        [string]$Command
    )

    Write-Verbose "Fyls: Executing command - $Command"

    try {
        Invoke-Expression $Command
    }
    catch {
        Write-Error "Fyls: Failed to execute command - $Command"
        Write-Error "Fyls: Error details - $($_.Exception.Message)"
    }
}

#endregion

#region Test
function Test-Fyls {
    <#
    .SYNOPSIS
        Runs diagnostic and feature tests on the Get-Children function.
    .DESCRIPTION
        Performs comprehensive testing of fyls functionality including tool detection,
        command building, and various parameter combinations.
    .EXAMPLE
        Test-Fyls
    #>
    [CmdletBinding()]
    param()

    $VerbosePreference = 'Continue'
    $DebugPreference = 'Continue'

    Write-Host "`n=== Fyls Tool Detection Tests ==="
    Write-Host "`nTesting tool availability:"

    $tools = @('eza', 'lsd', 'ls', 'powershell')
    foreach ($tool in $tools) {
        $result = Test-ToolAvailability -ToolName $tool
        $status = if ($result.Found) { "✓" } else { "✗" }
        Write-Host "  $status $tool" -ForegroundColor $(if ($result.Found) { "Green" } else { "Red" })
        if ($result.Found -and $result.Path) {
            Write-Host "    Path: $($result.Path)" -ForegroundColor Gray
        }
    }

    Write-Host "`n=== Basic Fyls Command Tests ==="

    Write-Host "`nTest 1: Basic directory listing"
    Get-Children -ShowCommand

    Write-Host "`nTest 2: Long format with all files"
    Get-Children -Long -All -ShowCommand

    Write-Host "`nTest 3: Pretty output with tree view"
    Get-Children -Pretty -Tree -Depth 2 -ShowCommand

    Write-Host "`nTest 4: Directories only, sorted by size"
    Get-Children -DirectoryOnly -SortSize -ShowCommand

    Write-Host "`nTest 5: Recursive with git status"
    Get-Children -Recursive -Git -ShowCommand

    Write-Host "`n=== Advanced Parameter Tests ==="

    Write-Host "`nTest 6: Force specific tool (if available)"
    $bestTool = Get-BestAvailableTool
    if ($bestTool.Found) {
        Get-Children -Tool $bestTool.Name -Long -ShowCommand
    }

    Write-Host "`nTest 7: Custom sort and permission display"
    Get-Children -Sort time -Permission octal -Long -ShowCommand

    Write-Host "`nTest 8: No colors, no icons, directories first"
    Get-Children -NoColor -NoIcons -DirFirst -ShowCommand

    Write-Host "`n=== Configuration Resolution Tests ==="
    Write-Host "`nTesting parameter resolution..."

    $testParams = @{
        Pretty = $true
        SortTime = $true
        Depth = 3
        All = $true
    }

    $config = Initialize-FylsConfig -Parameters $testParams
    $config = Resolve-SortPreferences -Config $config
    $config = Resolve-DisplayPreferences -Config $config

    Write-Host "Config resolution test:"
    Write-Host "  Sort: $($config.Sort) (should be 'time')"
    Write-Host "  Color: $($config.Color) (should be True)"
    Write-Host "  Icons: $($config.Icons) (should be True)"
    Write-Host "  RecursionMode: $($config.RecursionMode) (should be 'tree')"
}

#endregion

#region Export
#@ Export all public functions
Export-ModuleMember -Function @(
    'Get-Children',
    'Test-GetChildren'
)

#@ Set up aliases
Set-Alias -Name fyls -Value Get-Children
Set-Alias -Name ls -Value Get-Children -Force -Option AllScope
Set-Alias -Name ll -Value Get-Children -Force -Option AllScope

#endregion
