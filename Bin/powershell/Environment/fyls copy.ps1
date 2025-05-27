#!/usr/bin/env pwsh
#Bin/powershell/environment/fyls.psm1
# PowerShell port of fyls - ls wrapper that tries eza, then lsd, then falls back to ls/Get-ChildItem

param(
    [switch]$Help,
    [switch]$Version,
    [switch]$Detailed,  # Renamed from Verbose to avoid conflict
    [string]$Tool,
    [switch]$All,
    [switch]$Color,
    [switch]$NoColor,
    [switch]$DirFirst,
    [switch]$DirLast,
    [switch]$NoGroup,
    [int]$Depth,
    [switch]$DirectoryOnly,
    [switch]$Git,
    [switch]$NoGit,
    [switch]$GitIgnore,
    [switch]$Header,
    [switch]$Hyperlink,
    [switch]$NoHyperlink,
    [switch]$Icons,
    [switch]$NoIcons,
    [switch]$Long,
    [switch]$Link,
    [switch]$Octal,
    [switch]$Pagination,
    [switch]$Pretty,
    [string]$Permission,
    [switch]$Recursive,
    [string]$Sort,
    [switch]$SortSize,
    [switch]$SortNone,
    [switch]$SortTime,
    [switch]$SortVersion,
    [switch]$SortExtension,
    [switch]$Tree,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Path
)

# Global variables
$script:debug = $false
$script:verbose = $false
$script:delimiter = [char]31  # ASCII Unit Separator

# Usage strings
$script:SCR_USAGE_BASIC = @"
fyls - A cross-platform ls wrapper
Usage: fyls [OPTIONS] [PATH...]
Use --help for detailed options.
"@

$script:SCR_USAGE_GUIDE = @"
fyls - A cross-platform ls wrapper that tries eza, then lsd, then falls back to native ls

USAGE:
    fyls [OPTIONS] [PATH...]

OPTIONS:
    -Help, -h              Show this help message
    -Version               Show version information
    -Detailed, -d          Enable debug output (show command without executing)
    -Tool <tool>           Force specific tool (eza, lsd, ls, powershell)

    DISPLAY OPTIONS:
    -All, -a               Show hidden files
    -Color, -c             Force color output
    -NoColor               Disable color output
    -DirFirst              Show directories first
    -DirLast               Show directories last
    -NoGroup               Don't group directories
    -Long, -l              Long format
    -Pretty, -P            Enable color and icons

    FILTERING:
    -DirectoryOnly, -D     Show only directories
    -Link, -L              Show only symlinks
    -Depth <n>             Limit recursion depth
    -GitIgnore, -I         Respect .gitignore

    FEATURES:
    -Git, -g               Show git status
    -NoGit                 Disable git status
    -Header, -G            Show headers
    -Hyperlink, -H         Enable hyperlinks
    -NoHyperlink           Disable hyperlinks
    -Icons, -i             Show icons
    -NoIcons               Disable icons
    -Permission <type>     Permission format (rwx, octal, attributes, none)

    RECURSION:
    -Recursive, -R         Recursive listing (flat)
    -Tree, -t              Tree view

    SORTING:
    -Sort <field>          Sort by field (size, time, version, extension, git, none, name)
    -SortSize, -S          Sort by size
    -SortTime, -T          Sort by time
    -SortVersion, -V       Sort by version
    -SortExtension, -X     Sort by extension
    -SortNone, -N          No sorting

    OTHER:
    -Pagination            Enable pagination
    -Octal, -o             Show octal permissions

EXAMPLES:
    fyls -la               # Show all files in long format
    fyls -tree -depth 2    # Show tree view with depth 2
    fyls -pretty           # Show with colors and icons
    fyls -Detailed            # Show command that would be executed
"@

$script:SCR_VERSION = "fyls PowerShell v1.0.0"

function Main {
    Set-Defaults
    if (Parse-Arguments) { return }
    Set-Environment
    Execute-Process
}

function Set-Defaults {
    #@ Initialize global variables/flags
    $script:debug = $script:Detailed  # Use the script-scoped parameter
    $script:verbose = $false  # This can be controlled by PowerShell's built-in -Verbose

    #@ Initialize flags
    $script:all = $false
    $script:color = $true
    $script:depth = 0
    $script:git = $true
    $script:git_ignore = $false
    $script:header = $false
    $script:hyperlink = $true
    $script:icons = $true
    $script:long = $false
    $script:pagination = $false
    $script:permission = "none"
    $script:permission_options = @("attributes", "rwx", "octal", "none")
    $script:priority = "directories"
    $script:priority_options = @("directories", "files", "none")
    $script:recursion = "none"
    $script:recursion_options = @("flat", "none", "tree")
    $script:sort = "name"
    $script:sort_options = @("size", "time", "version", "extension", "none", "name", "git")
    $script:target = "all"
    $script:target_options = @("all", "directory", "symlink", "recursive")
    $script:tree = $false
    $script:args = @()
    $script:cmd = ""
}

function Parse-Arguments {
    #@ Handle help and version first
    if ($script:Help) {
        Write-Pretty $script:SCR_USAGE_GUIDE
        return $true
    }

    if ($script:Version) {
        Write-Pretty $script:SCR_VERSION
        return $true
    }

    #@ Set flags based on parameters
    if ($script:Tool) {
        if ($script:Tool -notin @("eza", "lsd", "ls", "powershell")) {
            Write-Error "Invalid tool: $script:Tool. Available: eza, lsd, ls, powershell"
            return $true
        }
        $script:forced_tool = $script:Tool
    }

    $script:all = $script:All
    $script:color = if ($script:NoColor) { $false } else { $script:Color -or $script:color }
    $script:git = if ($script:NoGit) { $false } else { $script:Git -or $script:git }
    $script:git_ignore = $script:GitIgnore
    $script:header = $script:Header
    $script:hyperlink = if ($script:NoHyperlink) { $false } else { $script:Hyperlink -or $script:hyperlink }
    $script:icons = if ($script:NoIcons) { $false } else { $script:Icons -or $script:icons }
    $script:long = $script:Long
    $script:pagination = $script:Pagination

    if ($script:Pretty) {
        $script:color = $true
        $script:icons = $true
    }

    if ($script:DirFirst) { $script:priority = "directories" }
    if ($script:DirLast) { $script:priority = "files" }
    if ($script:NoGroup) { $script:priority = "none" }

    if ($script:Depth -gt 0) { $script:depth = $script:Depth }

    if ($script:DirectoryOnly) { $script:target = "directory" }
    if ($script:Link) { $script:target = "link" }

    if ($script:Permission) {
        if ($script:Permission -notin $script:permission_options) {
            Write-Error "Invalid permission option: $script:Permission. Available: $($script:permission_options -join ', ')"
            return $true
        }
        $script:permission = $script:Permission
    }

    if ($script:Recursive) { $script:recursion = "flat" }
    if ($script:Tree) { $script:recursion = "tree" }

    if ($script:Sort) {
        if ($script:Sort -notin $script:sort_options) {
            Write-Error "Invalid sort option: $script:Sort. Available: $($script:sort_options -join ', ')"
            return $true
        }
        $script:sort = $script:Sort
    }

    if ($script:SortSize) { $script:sort = "size" }
    if ($script:SortTime) { $script:sort = "time" }
    if ($script:SortVersion) { $script:sort = "version" }
    if ($script:SortExtension) { $script:sort = "extension" }
    if ($script:SortNone) { $script:sort = "none" }

    #@ Store remaining arguments as paths
    if ($script:Path) {
        $script:args = $script:Path
    } else {
        $script:args = @(".")
    }

    return $false
}

function Set-Environment {
    #@ Validate depth and set recursion if needed
    if ($script:depth -gt 0 -and $script:recursion -eq "none") {
        $script:recursion = "tree"
    }

    #@ Determine which command to use
    $script:cmd = ""
    if ($script:forced_tool) {
        switch ($script:forced_tool) {
            "eza" { Use-Eza }
            "lsd" { Use-Lsd }
            "ls" { Use-Ls }
            "powershell" { Use-PowerShell }
        }
    } else {
        #@ Try commands in order of preference
        if (-not $script:cmd) { Use-Eza }
        if (-not $script:cmd) { Use-Lsd }
        if (-not $script:cmd) { Use-Ls }
        if (-not $script:cmd) { Use-PowerShell }
    }

    #@ Add pagination if requested
    if ($script:pagination) {
        $pager = Get-Command "bat" -ErrorAction SilentlyContinue
        if ($pager) {
            $script:cmd = "$($script:cmd) | bat --color=always --style=plain"
        } else {
            $script:cmd = "$($script:cmd) | more"
        }
    }
}

function Check-Command {
    param(
        [string]$EnvVar,
        [string]$Command
    )

    #@ Get command from environment variable or PATH
    $envPath = [Environment]::GetEnvironmentVariable($EnvVar)
    if ($envPath -and (Test-Path $envPath)) {
        return $envPath
    }

    $cmd = Get-Command $Command -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    return $null
}

function Use-Eza {
    $ezaCmd = Check-Command "CMD_EZA" "eza"
    if (-not $ezaCmd) { return }

    $options = @($ezaCmd)

    if ($script:all) { $options += "--almost-all" }
    if ($script:color) { $options += "--color", "always", "--color-scale" }

    switch ($script:priority) {
        "directories" { $options += "--group-directories-first" }
        "files" { $options += "--group-directories-last" }
    }

    if ($script:icons) { $options += "--icons", "always" }
    if ($script:hyperlink) { $options += "--hyperlink" }

    if ($script:long) {
        $options += "--long"
        if ($script:git) { $options += "--git" }
    }

    if ($script:git_ignore) { $options += "--git-ignore" }

    switch ($script:permission) {
        "none" { $options += "--no-permissions" }
        default { $options += "--octal-permissions" }
    }

    switch ($script:target) {
        "file" { $options += "--only-files" }
        "directory" { $options += "--only-dirs" }
    }

    switch ($script:recursion) {
        "flat" {
            $options += "--recurse"
            if ($script:depth -gt 0) { $options += "--level", $script:depth }
        }
        "tree" {
            $options += "--tree"
            if ($script:depth -gt 0) { $options += "--level", $script:depth }
        }
    }

    if ($script:sort -ne "name") {
        $options += "--sort", $script:sort
    }

    $options += $script:args
    $script:cmd = ($options -join " ")
}

function Use-Lsd {
    $lsdCmd = Check-Command "CMD_LSD" "lsd"
    if (-not $lsdCmd) { return }

    $options = @($lsdCmd)

    if ($script:all) { $options += "--almost-all" }
    if ($script:color) { $options += "--color", "always" }

    switch ($script:priority) {
        "directories" { $options += "--group-dirs", "first" }
        "files" { $options += "--group-dirs", "last" }
        default { $options += "--group-dirs", "none" }
    }

    if ($script:icons) { $options += "--icon", "always" }
    if ($script:hyperlink) { $options += "--hyperlink", "always" }

    if ($script:long) {
        $options += "--long"
        if ($script:git) { $options += "--git" }
    }

    if ($script:permission -in @("rwx", "octal", "attributes")) {
        $options += "--permission", $script:permission
    }

    switch ($script:target) {
        "directory" { $options += "--directory-only" }
        "recursive" { $options += "--recursive" }
    }

    if ($script:recursion -eq "tree") { $options += "--tree" }

    if ($script:depth -gt 0 -and ($script:target -eq "recursive" -or $script:recursion -eq "tree")) {
        $options += "--depth", $script:depth
    }

    if ($script:sort -ne "name") {
        $options += "--sort", $script:sort
    }

    $options += $script:args
    $script:cmd = ($options -join " ")
}

function Use-Ls {
    $lsCmd = Check-Command "CMD_LS" "ls"
    if (-not $lsCmd) { return }

    $options = @($lsCmd)

    if ($script:all) { $options += "-la" } elseif ($script:long) { $options += "-l" }
    if ($script:color) { $options += "--color=always" }
    if ($script:recursion -eq "flat") { $options += "-R" }
    if ($script:target -eq "directory") { $options += "-d" }

    switch ($script:sort) {
        "size" { $options += "-S" }
        "time" { $options += "-t" }
        "extension" { $options += "-X" }
        "none" { $options += "-U" }
    }

    $options += $script:args
    $script:cmd = ($options -join " ")
}

function Use-PowerShell {
    $options = @("Get-ChildItem")

    if ($script:all) { $options += "-Force" }
    if ($script:recursion -eq "flat") { $options += "-Recurse" }
    if ($script:target -eq "directory") { $options += "-Directory" }
    if ($script:depth -gt 0) { $options += "-Depth", $script:depth }

    $options += $script:args
    $script:cmd = ($options -join " ")
}

function Execute-Process {
    if ($script:debug) {
        Write-Host "DEBUG: Command to execute: $script:cmd" -ForegroundColor Yellow
        return
    }

    #@ Print command if PowerShell's -Verbose is used
    Write-Verbose "Executing command: $script:cmd"

    #@ Execute the command
    try {
        Invoke-Expression $script:cmd
    } catch {
        Write-Error "Failed to execute command: $script:cmd"
        Write-Error $_.Exception.Message
    }
}

#@ Set up function to be available globally
function global:fyls {
    param(
        [switch]$Help,
        [switch]$Version,
        [switch]$Detailed,
        [string]$Tool,
        [switch]$All,
        [switch]$Color,
        [switch]$NoColor,
        [switch]$DirFirst,
        [switch]$DirLast,
        [switch]$NoGroup,
        [int]$Depth,
        [switch]$DirectoryOnly,
        [switch]$Git,
        [switch]$NoGit,
        [switch]$GitIgnore,
        [switch]$Header,
        [switch]$Hyperlink,
        [switch]$NoHyperlink,
        [switch]$Icons,
        [switch]$NoIcons,
        [switch]$Long,
        [switch]$Link,
        [switch]$Octal,
        [switch]$Pagination,
        [switch]$Pretty,
        [string]$Permission,
        [switch]$Recursive,
        [string]$Sort,
        [switch]$SortSize,
        [switch]$SortNone,
        [switch]$SortTime,
        [switch]$SortVersion,
        [switch]$SortExtension,
        [switch]$Tree,
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Path
    )

    # Store the original parameter values for the module functions to use
    $script:Help = $Help
    $script:Version = $Version
    $script:Detailed = $Detailed
    $script:Tool = $Tool
    $script:All = $All
    $script:Color = $Color
    $script:NoColor = $NoColor
    $script:DirFirst = $DirFirst
    $script:DirLast = $DirLast
    $script:NoGroup = $NoGroup
    $script:Depth = $Depth
    $script:DirectoryOnly = $DirectoryOnly
    $script:Git = $Git
    $script:NoGit = $NoGit
    $script:GitIgnore = $GitIgnore
    $script:Header = $Header
    $script:Hyperlink = $Hyperlink
    $script:NoHyperlink = $NoHyperlink
    $script:Icons = $Icons
    $script:NoIcons = $NoIcons
    $script:Long = $Long
    $script:Link = $Link
    $script:Octal = $Octal
    $script:Pagination = $Pagination
    $script:Pretty = $Pretty
    $script:Permission = $Permission
    $script:Recursive = $Recursive
    $script:Sort = $Sort
    $script:SortSize = $SortSize
    $script:SortNone = $SortNone
    $script:SortTime = $SortTime
    $script:SortVersion = $SortVersion
    $script:SortExtension = $SortExtension
    $script:Tree = $Tree
    $script:Path = $Path

    # Run the main logic
    Main
}

#@ If called directly (not dot-sourced), run main
if ($MyInvocation.InvocationName -ne '.') {
    Main
}
