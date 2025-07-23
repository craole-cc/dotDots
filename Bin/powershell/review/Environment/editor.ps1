#DOC PowerShell Editor Selection Script
#DOC
#DOC DESCRIPTION:
#DOC   Intelligent cross-platform editor selection and launching system for PowerShell.
#DOC   Automatically detects GUI/TUI environments and selects the best available editor
#DOC   from configurable preference lists.
#DOC
#DOC DEPENDENCIES:
#DOC   - Write-Pretty function (required for output formatting)
#DOC
#DOC USAGE:
#DOC   . .\editor-script.ps1    # Dot-source to load functions and aliases
#DOC
#DOC   Get-Editor               # Get current preferred editor
#DOC   Set-Editor code          # Set specific editor
#DOC   edit                      # Launch editor in current directory
#DOC   edit myfile.txt           # Launch editor with specific file
#DOC   Show-EditorConfig        # Display configuration and available editors
#DOC
#DOC ENVIRONMENT VARIABLES (optional):
#DOC   EDITOR_GUI     - Preferred GUI editors (e.g., "code|zed|sublime_text")
#DOC   EDITOR_TUI     - Preferred TUI editors (e.g., "hx|nvim|vim")
#DOC   VISUAL         - Standard *nix GUI editor variable
#DOC   EDITOR         - Standard *nix TUI editor variable
#DOC
#DOC EXPORTED FUNCTIONS:
#DOC   Get-Editor, Set-Editor, Get-PreferredEditor, Set-PreferredEditor,
#DOC   Invoke-Editor, Show-EditorConfig, Set-EditorPreference, Test-GuiEnvironment
#DOC
#DOC EXPORTED ALIASES:
#DOC   edit -> Invoke-Editor

#region Editor Configuration
$EditorConfig = @{
  DefaultTuiEditors = @('helix','hx', 'nvim', 'vim', 'nano')
  DefaultGuiEditors = @(
    'code-insiders',
    'code',
    'zed',
    'zeditor',
    'trae',
    'windsurf',
    'cursor',
    'notepad++',
    'sublime_text',
    'atom',
    'notepad'
  )
  CurrentEditor     = $null
  Delimiter         = '|'
}

function Test-GuiEnvironment {
  <#
    .SYNOPSIS
    Determines if a GUI environment is available for launching graphical editors

    .DESCRIPTION
    Intelligently detects GUI availability across different platforms and environments:
    - Windows: Always assumes GUI available (native desktop environment)
    - Unix/Linux: Checks for X11 (DISPLAY) or Wayland (WAYLAND_DISPLAY) environment variables
    - WSL: Detects GUI forwarding support (WSLg or X11 forwarding)

    This detection determines whether GUI editors (like VS Code, Zed) or TUI editors
    (like Helix, Neovim) should be prioritized in the selection process.

    .OUTPUTS
    [bool] True if GUI environment is detected, False for TUI-only environments

    .EXAMPLE
    Test-GuiEnvironment
    # Returns: True (on Windows or Linux with GUI)

    .EXAMPLE
    if (Test-GuiEnvironment) {
        Write-Host "GUI editors will be prioritized"
    } else {
        Write-Host "TUI editors only"
    }
    #>
  [CmdletBinding()]
  param()

  # Windows typically has GUI available
  if ($IsWindows -or $env:OS -like '*Windows*') {
    return $true
  }

  # Check for X11 or Wayland on Unix/Linux
  if ($env:DISPLAY -or $env:WAYLAND_DISPLAY) {
    return $true
  }

  # Check WSL with GUI support
  if ($env:WSL_DISTRO_NAME -and $env:DISPLAY) {
    return $true
  }

  return $false
}
#endregion

#region Editor Discovery
function Get-AvailableEditor {
  <#
    .SYNOPSIS
    Searches for the first available editor from a prioritized list

    .DESCRIPTION
    Iterates through a list of editor commands and returns the first one that:
    - Is found in the system PATH
    - Has an executable file that exists and is accessible
    - Can be successfully resolved by Get-Command

    This function is the core discovery mechanism that ensures we only attempt
    to launch editors that are actually installed and available.

    .PARAMETER EditorList
    Array of editor command names to check in priority order.
    Examples: @('code', 'hx', 'nvim', 'vim')

    .PARAMETER ReturnPath
    When specified, returns the full executable path instead of just the command name.
    Useful for situations where the command name alone might not work reliably.

    .OUTPUTS
    [string] The first available editor name or path, or $null if none found

    .EXAMPLE
    Get-AvailableEditor
    # Returns the first available editor from $EditorConfig.DefaultGuiEditors if installed and Gui environment is detected
    # Returns the first available editor from $EditorConfig.DefaultTuiEditors otherwise

    .EXAMPLE
    Get-AvailableEditor -EditorList @('code', 'hx', 'nvim', 'vim')
    # Returns: "code" (if VS Code is installed)

    .EXAMPLE
    Get-AvailableEditor -EditorList @('nonexistent', 'vim') -ReturnPath
    # Returns: "/usr/bin/vim" (full path to vim)
    #>
  #>
  [CmdletBinding()]
  param(
    [Parameter()]
    [string[]]$EditorList,

    [switch]$ReturnPath
  )

  #{ Ensure we have something to check
  if (-not $EditorList -or $EditorList.Length -eq 0) {
    if (Test-GuiEnvironment) {
      $EditorList = $EditorConfig.DefaultGuiEditors + $EditorConfig.DefaultTuiEditors
    }
    else {
      $EditorList = $EditorConfig.DefaultTuiEditors
    }
  }
  Write-Pretty -Tag 'Verbose' -Scope 'Name'`
    "Checking for the first available of the following $($EditorList.Count) editors " `
    "$($EditorList -join ', ')"

  #{ Try to find the first available editor
  foreach ($editor in $EditorList) {
    #{ Skip empty strings
    if ([string]::IsNullOrWhiteSpace($editor)) { continue }
    $editorIndex = $EditorList.IndexOf($editor)
    $editorIndexStr = & Get-OrdinalString ($editorIndex + 1)

    #{ Try to resolve the command of the editor
    $command = Get-CommandFirst -Name $editor -VerifyExecutable
    if ($command) {
      Write-Pretty -Tag 'Trace' -Scope 'Name' `
        "Found the $editorIndexStr listed editor, '${editor}'." `
        "$($command.Name)" "$($command.Source)"

      #{ Break the loop, returning the ediror path, if requested
      if ($ReturnPath) { return $command.Source } else { return $command.Name }
    }
    else {
      Write-Pretty -Tag 'Verbose' -Scope 'Name' -OneLine `
        "Failed to resolve editor: $editor"

      #{ Check the next editor in the list
      continue
    }
  }

  Write-Pretty -Tag 'Verbose' 'No available editors found'
  return $null
}

function Split-EditorString {
  <#
    .SYNOPSIS
    Parses editor preference strings with flexible delimiter support

    .DESCRIPTION
    Converts user-friendly editor preference strings into arrays for processing.
    Handles multiple common delimiters and normalizes input to ensure consistent
    parsing regardless of how users specify their preferences.

    Supported input formats:
    - "code,hx,nvim"           (comma-separated)
    - "code | hx | nvim"       (pipe-separated)
    - "code:hx:nvim"           (colon-separated)
    - "code  hx  nvim"         (space-separated)
    - "code, hx | nvim: vim"   (mixed delimiters)

    Automatically filters out empty values and 'none' placeholders.

    .PARAMETER EditorString
    String containing editor names separated by various delimiters.
    Can be empty, null, or whitespace (returns empty array).

    .PARAMETER Delimiter
    Primary delimiter to normalize to during processing.
    Default: '|' (pipe character from $EditorConfig.Delimiter)

    .OUTPUTS
    [string[]] Array of editor names with empty/invalid entries filtered out

    .EXAMPLE
    Split-EditorString "code, hx | nvim: vim"
    # Returns: @('code', 'hx', 'nvim', 'vim')

    .EXAMPLE
    Split-EditorString "  code  ,  , none,   hx  "
    # Returns: @('code', 'hx')
    #>
  [CmdletBinding()]
  param(
    [string]$EditorString,
    [string]$Delimiter = $EditorConfig.Delimiter
  )

  if ([string]::IsNullOrWhiteSpace($EditorString)) {
    return @()
  }

  # Normalize multiple delimiters: comma, pipe, colon, multiple spaces
  $normalized = $EditorString `
    -replace ',\s*', $Delimiter `
    -replace '\|\s*', $Delimiter `
    -replace ':\s*', $Delimiter `
    -replace '\s{2,}', $Delimiter `
    -replace '\s+', $Delimiter

  # Split and filter out empty/none values
  $editors = $normalized -split [regex]::Escape($Delimiter) | Where-Object {
    -not [string]::IsNullOrWhiteSpace($_) -and $_ -ne 'none'
  }

  return $editors
}

#endregion

#region Editor Selection
function Get-PreferredEditor {
  <#
    .SYNOPSIS
    Gets the preferred editor based on environment and configuration

    .PARAMETER CustomTuiEditors
    Custom TUI editors string (overrides environment/defaults)

    .PARAMETER CustomGuiEditors
    Custom GUI editors string (overrides environment/defaults)

    .PARAMETER ReturnPath
    Return full path instead of command name

    .PARAMETER Force
    Force re-evaluation even if editor is already cached
    #>
  [CmdletBinding()]
  param(
    [string]$CustomTuiEditors,
    [string]$CustomGuiEditors,
    [switch]$ReturnPath,
    [switch]$Force
  )

  #{ Return cached editor if available and not forcing re-evaluation
  if (-not $Force -and $EditorConfig.CurrentEditor -and -not $ReturnPath) {
    return $EditorConfig.CurrentEditor
  }

  #{ Get TUI editors from various sources (priority order)
  $tuiEditors = if ($CustomTuiEditors) {
    Split-EditorString $CustomTuiEditors
  }
  elseif ($env:EDITOR_TUI) {
    Split-EditorString $env:EDITOR_TUI
  }
  elseif ($env:EDITOR) {
    Split-EditorString $env:EDITOR
  }
  else {
    $EditorConfig.DefaultTuiEditors
  }

  #{ Get GUI editors from various sources (priority order)
  $guiEditors = if ($CustomGuiEditors) {
    Split-EditorString $CustomGuiEditors
  }
  elseif ($env:EDITOR_GUI) {
    Split-EditorString $env:EDITOR_GUI
  }
  elseif ($env:VISUAL) {
    Split-EditorString $env:VISUAL
  }
  else {
    $EditorConfig.DefaultGuiEditors
  }

  # Determine editor priority based on environment
  $editorList = if (Test-GuiEnvironment) {
    $guiEditors + $tuiEditors  # GUI first, TUI fallback
  }
  else {
    $tuiEditors  # TUI only in non-GUI environments
  }

  # Find first available editor
  $selectedEditor = Get-AvailableEditor -EditorList $editorList -ReturnPath:$ReturnPath

  if ($selectedEditor) {
    if (-not $ReturnPath) {
      $EditorConfig.CurrentEditor = $selectedEditor
    }
    return $selectedEditor
  }

  # Ultimate fallbacks
  $fallback = if ($IsWindows -or $env:OS -like '*Windows*') { 'notepad' } else { 'vi' }

  if (-not $ReturnPath) {
    $EditorConfig.CurrentEditor = $fallback
  }

  return $fallback
}

function Set-PreferredEditor {
  <#
    .SYNOPSIS
    Sets the preferred editor configuration

    .PARAMETER TuiEditors
    String of TUI editors in preference order

    .PARAMETER GuiEditors
    String of GUI editors in preference order
    #>
  [CmdletBinding()]
  param(
    [string]$TuiEditors,
    [string]$GuiEditors
  )

  # Clear cached editor to force re-evaluation
  $EditorConfig.CurrentEditor = $null

  # Get new preferred editor
  $newEditor = Get-PreferredEditor -CustomTuiEditors $TuiEditors -CustomGuiEditors $GuiEditors

  Write-Pretty -Tag 'Verbose' 'Editor preference updated: ' -NoNewline
  Write-Pretty -Tag 'Verbose' $newEditor -ForegroundColor Green

  return $newEditor
}
#endregion

#region New Required Functions
function Get-Editor {
  <#
    .SYNOPSIS
    Gets the current preferred editor (simplified interface)

    .DESCRIPTION
    Simplified wrapper around Get-PreferredEditor that provides a clean,
    intuitive interface for retrieving the currently configured editor.

    This is the recommended function for scripts and interactive use when
    you just need to know which editor is currently selected.

    .PARAMETER ReturnPath
    When specified, returns the full executable path instead of just the command name.
    Useful when you need the absolute path for direct execution or verification.

    .OUTPUTS
    [string] Current preferred editor name or full path

    .EXAMPLE
    Get-Editor
    # Returns: "code"

    .EXAMPLE
    Get-Editor -ReturnPath
    # Returns: "C:\Users\Username\AppData\Local\Programs\Microsoft VS Code\Code.exe"

    .NOTES
    This function uses caching for performance - the editor is determined once
    and reused until explicitly changed with Set-Editor or cleared with -Force
    on the underlying Get-PreferredEditor function.
    #>
  [CmdletBinding()]
  param(
    [switch]$ReturnPath
  )

  return Get-PreferredEditor -ReturnPath:$ReturnPath
}

function Set-Editor {
  <#
    .SYNOPSIS
    Sets the preferred editor (simplified interface)

    .DESCRIPTION
    Simplified wrapper for configuring your preferred editor. Supports both
    single editor selection and advanced preference configuration.

    Single editor mode forces a specific editor regardless of environment.
    Preference mode uses intelligent selection based on GUI/TUI availability.

    .PARAMETER Editor
    Single editor name to set as preferred (bypasses intelligent selection).
    The editor doesn't need to be installed - useful for portable configurations
    where different editors may be available in different environments.

    .PARAMETER TuiEditors
    String of TUI (Terminal User Interface) editors in preference order.
    Used when GUI environment is not available or as fallback.
    Format: "hx|nvim|vim" or "hx, nvim, vim" (flexible delimiters)

    .PARAMETER GuiEditors
    String of GUI (Graphical User Interface) editors in preference order.
    Prioritized when GUI environment is detected.
    Format: "code|zed|sublime_text" or "code, zed, sublime_text"

    .OUTPUTS
    [string] The editor that was selected/configured

    .EXAMPLE
    Set-Editor code
    # Forces VS Code as the preferred editor

    .EXAMPLE
    Set-Editor -TuiEditors "hx,nvim,vim" -GuiEditors "code,zed"
    # Configures intelligent selection with custom preferences

    .EXAMPLE
    # Set editor from environment variable
    Set-Editor $env:PREFERRED_EDITOR

    .NOTES
    When using single editor mode, the specified editor becomes the preferred
    choice regardless of GUI/TUI environment detection. When using preference
    mode, the system intelligently selects based on environment and availability.
    #>
  [CmdletBinding(DefaultParameterSetName = 'Single')]
  param(
    [Parameter(ParameterSetName = 'Single', Position = 0)]
    [string]$Editor,

    [Parameter(ParameterSetName = 'Separate')]
    [string]$TuiEditors,

    [Parameter(ParameterSetName = 'Separate')]
    [string]$GuiEditors
  )

  if ($Editor) {
    # Set single editor
    $EditorConfig.CurrentEditor = $Editor
    Write-Verbose "Editor set to: $Editor"
    return $Editor
  }
  else {
    # Use intelligent selection with custom preferences
    return Set-PreferredEditor -TuiEditors $TuiEditors -GuiEditors $GuiEditors
  }
}
#endregion

#region Public Interface
function Invoke-Editor {
  <#
    .SYNOPSIS
    Launches the preferred editor with intelligent argument handling

    .DESCRIPTION
    Main editor launching function that provides a robust interface for opening
    files and directories in your preferred editor. Handles path resolution,
    argument passing, and fallback execution strategies.

    Features:
    - Automatic current directory default when no path specified
    - Intelligent editor selection with fallback mechanisms
    - Robust error handling with alternative execution paths
    - Support for additional editor arguments and flags
    - Temporary editor override capability

    .PARAMETER Path
    Path to open in the editor. Can be:
    - File path (relative or absolute)
    - Directory path
    - Empty/null (defaults to current directory)

    The path is passed as the first argument to the editor.

    .PARAMETER Arguments
    Additional arguments to pass to the editor after the path.
    Useful for editor-specific flags like "--new-window" or "--goto line:column"

    .PARAMETER Editor
    Temporarily override the configured editor for this single invocation.
    Does not change the persistent editor preference.

    .OUTPUTS
    None (launches external editor process)

    .EXAMPLE
    Invoke-Editor
    # Opens current directory in preferred editor

    .EXAMPLE
    Invoke-Editor myfile.txt
    # Opens myfile.txt in preferred editor

    .EXAMPLE
    Invoke-Editor -Path "src/" -Arguments @("--new-window")
    # Opens src/ directory in new window

    .EXAMPLE
    Invoke-Editor myfile.txt -Editor vim
    # Opens myfile.txt in vim (temporary override)

    .NOTES
    The function attempts multiple execution strategies:
    1. Execute using command name
    2. If that fails, try using full executable path
    3. Provide detailed error information if both fail

    This approach handles edge cases where PATH resolution or shell integration
    might cause issues with certain editors.
    #>
  [CmdletBinding()]
  param(
    [string]$Path,
    [string[]]$Arguments = @(),
    [string]$Editor
  )

  # Default to current directory if no path provided
  if ([string]::IsNullOrWhiteSpace($Path)) {
    $Path = (Get-Location).Path
  }

  $editorToUse = if ($Editor) { $Editor } else { Get-AvailableEditor }
  $editorPath = Get-AvailableEditor -ReturnPath

  if (-not $editorToUse) {
    Write-Error 'No suitable editor found'
    return
  }

  try {
    $allArgs = @($Path) + $Arguments
    Write-Verbose "Opening '$Path' with $editorToUse"

    & $editorToUse @allArgs
  }
  catch {
    Write-Warning "Failed to launch $editorToUse with path '$Path'. Error: $($_.Exception.Message)"

    # Try with full path if command name failed
    if ($editorPath -and $editorPath -ne $editorToUse) {
      try {
        & $editorPath @allArgs
      }
      catch {
        Write-Error "Failed to launch editor: $($_.Exception.Message)"
      }
    }
  }
}

function Show-EditorConfig {
  <#
    .SYNOPSIS
    Displays comprehensive editor configuration and system analysis

    .DESCRIPTION
    Provides detailed information about the current editor configuration,
    environment detection results, and system-wide editor availability.

    This diagnostic function is useful for:
    - Troubleshooting editor selection issues
    - Understanding why a specific editor was chosen
    - Discovering what editors are available on the system
    - Verifying environment variable configuration

    .OUTPUTS
    None (displays formatted information to console)

    .EXAMPLE
    Show-EditorConfig
    # Displays complete configuration analysis

    .NOTES
    The output includes:
    - Current selected editor and its full path
    - GUI/TUI environment detection results
    - All relevant environment variables and their values
    - Complete list of editors with availability status
    #>
  [CmdletBinding()]
  param()

  Write-Host "`n=== Editor Configuration ===" -ForegroundColor Cyan

  # Current editor
  $currentEditor = Get-PreferredEditor
  $currentPath = Get-PreferredEditor -ReturnPath
  $hasGui = Test-GuiEnvironment

  Write-Pretty -Tag 'Editor' 'Current Editor: ' -NoNewline
  Write-Pretty -Tag 'Editor' $currentEditor -ForegroundColor Green
  Write-Pretty -Tag 'Editor' 'Editor Path: ' -NoNewline
  Write-Pretty -Tag 'Editor' $currentPath -ForegroundColor Green
  Write-Pretty -Tag 'Editor' 'Environment: ' -NoNewline
  Write-Pretty -Tag 'Editor' $(if ($hasGui) { 'GUI Available' } else { 'TUI Only' }) -ForegroundColor Green

  # Environment variables
  Write-Pretty -Tag 'Editor' "`nEnvironment Variables:"
  @('EDITOR_GUI', 'EDITOR_TUI', 'VISUAL', 'EDITOR') | ForEach-Object {
    $value = Get-Item "env:$_" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Value
    Write-Pretty -Tag 'Editor' "  ${_}: " -NoNewline
    Write-Pretty -Tag 'Editor' $(if ($value) { $value } else { '(not set)' }) -ForegroundColor $(if ($value) { 'Green' } else { 'Gray' })
  }

  # Available editors
  Write-Pretty -Tag 'Editor' "`nAvailable Editors:"
  $allEditors = ($EditorConfig.DefaultGuiEditors + $EditorConfig.DefaultTuiEditors) | Sort-Object -Unique

  foreach ($editor in $allEditors) {
    $available = Get-Command $editor -ErrorAction SilentlyContinue
    $status = if ($available) { '✓' } else { '✗' }
    $color = if ($available) { 'Green' } else { 'Red' }
    Write-Pretty -Tag 'Editor' "  $status $editor" -ForegroundColor $color
  }
}

function Set-EditorPreference {
  <#
    .SYNOPSIS
    Interactive editor preference configuration

    .PARAMETER Editor
    Set a single editor as preferred

    .PARAMETER TuiEditors
    Set TUI editors preference string

    .PARAMETER GuiEditors
    Set GUI editors preference string

    .PARAMETER Show
    Show current configuration
    #>
  [CmdletBinding()]
  param(
    [Parameter(ParameterSetName = 'Single')]
    [string]$Editor,

    [Parameter(ParameterSetName = 'Separate')]
    [string]$TuiEditors,

    [Parameter(ParameterSetName = 'Separate')]
    [string]$GuiEditors,

    [Parameter(ParameterSetName = 'Show')]
    [switch]$Show
  )

  if ($Show -or (-not $Editor -and -not $TuiEditors -and -not $GuiEditors)) {
    Show-EditorConfig
    return
  }

  if ($Editor) {
    # Force single editor
    Set-Editor -Editor $Editor
  }
  else {
    # Use intelligent selection with custom preferences
    Set-Editor -TuiEditors $TuiEditors -GuiEditors $GuiEditors
  }
}
#endregion

#region Export-EditorVariables
function Export-EditorVariables {
  <#
    .SYNOPSIS
    Sets and exports EDITOR and VISUAL environment variables based on detected environment

    .DESCRIPTION
    Configures standard Unix environment variables for editor selection:
    - In GUI environments: Sets both EDITOR and VISUAL to the same GUI editor
    - In TUI-only environments: Sets only EDITOR variable to best TUI editor

    This ensures compatibility with Unix/Linux tools and scripts that rely on
    these standard environment variables for editor selection.

    .PARAMETER TuiEditor
    Override the TUI editor to export as EDITOR variable.
    If not specified, uses the best available TUI editor from preferences.

    .PARAMETER GuiEditor
    Override the GUI editor to export as VISUAL variable.
    If not specified, uses the best available GUI editor from preferences.

    .PARAMETER Scope
    PowerShell scope for the environment variables.
    - 'Process' (default): Current PowerShell process only
    - 'User': Current user profile (persistent)
    - 'Machine': System-wide (requires admin, persistent)

    .OUTPUTS
    None (sets environment variables)

    .EXAMPLE
    Export-EditorVariables
    # Auto-detects and exports appropriate variables

    .EXAMPLE
    Export-EditorVariables -TuiEditor "nvim" -GuiEditor "code"
    # Forces specific editors for EDITOR and VISUAL

    .EXAMPLE
    Export-EditorVariables -Scope User
    # Makes the variables persistent for the user profile

    .NOTES
    In GUI environments, both EDITOR and VISUAL are set to the same GUI editor
    for consistency and performance. In TUI-only environments, only EDITOR is set.
    #>
  [CmdletBinding()]
  param(
    [string]$TuiEditor,
    [string]$GuiEditor,
    [ValidateSet('Process', 'User', 'Machine')]
    [string]$Scope = 'Process'
  )

  if ($TuiEditor) {
    $TuiEditor = Get-AvailableEditor -EditorList ($TuiEditor + $EditorConfig.DefaultTuiEditors)
  }

  if ($GuiEditor) {
    $GuiEditor = Get-AvailableEditor -EditorList ($GuiEditor + $EditorConfig.DefaultGuiEditors)
  }

  $availableEditor = Get-AvailableEditor
  if ($availableEditor) {
    $editorToUse = if ($TuiEditor) { $TuiEditor } else { $availableEditor }
    [System.Environment]::SetEnvironmentVariable('EDITOR', $editorToUse, $Scope)
    Write-Pretty -DebugEnv 'EDITOR' "$availableEditor"

    $hasGui = Test-GuiEnvironment
    if ($hasGui) {
      $editorToUse = if ($GuiEditor) { $GuiEditor } else { $availableEditor }
      [System.Environment]::SetEnvironmentVariable('VISUAL', $availableEditor, $Scope)
      Write-Pretty -DebugEnv 'VISUAL' "$editorToUse"
    }
    else {
      #{ Clear VISUAL in TUI-only environments
      Write-Pretty -Tag 'Verbose' -Scope 'Name' 'Removed VISUAL (TUI-only environment)'
      if ($Scope -eq 'Process') {
        Remove-Item 'env:VISUAL' -ErrorAction SilentlyContinue
      }
      else {
        [System.Environment]::SetEnvironmentVariable('VISUAL', $null, $Scope)
      }
    }
  }
  else {
    Write-Pretty -Tag 'Warning' -Scope 'Name' 'No available editor found'
  }


  # $hasGui = Test-GuiEnvironment

  # if ($hasGui) {
  #   #{ In GUI environment: Set both EDITOR and VISUAL to same GUI editor
  #   if ($GuiEditor) { $editorToUse = $GuiEditor }
  #   else {
  #     #{ Get best available GUI editor (only search once)
  #     if ($env:EDITOR_GUI) {
  #       Split-EditorString $env:EDITOR_GUI
  #       $editorToUse = Get-AvailableEditor -EditorList $(Split-EditorString $env:EDITOR_GUI)
  #     }
  #     else {
  #       $editorToUse = Get-AvailableEditor
  #     }
  #   }

  #   if ($editorToUse) {
  #     #{ Set both to the same GUI editor
  #     if ($Scope -eq 'Process') {
  #       $env:EDITOR = $editorToUse
  #       $env:VISUAL = $editorToUse
  #     }
  #     else {
  #       [System.Environment]::SetEnvironmentVariable('EDITOR', $editorToUse, $Scope)
  #       [System.Environment]::SetEnvironmentVariable('VISUAL', $editorToUse, $Scope)
  #     }
  #     Write-Pretty -Tag "Debug" -Scope "Name" `
  #       "VISUAL| EDITOR => $editorToUse '
  #   }
  #   else {
  #     Write-Pretty -Tag 'Warning" -Scope "Name" `
  #       "No suitable GUI editor found"
  #   }
  # }
  # else {
  #   #{ In TUI-only environment: Set only EDITOR to best TUI editor
  #   $tuiEditorToUse = if ($TuiEditor) { $TuiEditor }
  #   else {
  #     #{ Get best available TUI editor
  #     $tuiEditors = if ($env:EDITOR_TUI) {
  #       Split-EditorString $env:EDITOR_TUI
  #     }
  #     else {
  #       $EditorConfig.DefaultTuiEditors
  #     }
  #     Get-AvailableEditor -EditorList $tuiEditors
  #   }

  #   if ($tuiEditorToUse) {
  #     if ($Scope -eq 'Process') {
  #       $env:EDITOR = $tuiEditorToUse
  #     }
  #     else {
  #       [System.Environment]::SetEnvironmentVariable('EDITOR', $tuiEditorToUse, $Scope)
  #     }

  #     Write-Pretty -Tag "Debug" -Scope "Name"  "EDITOR => $editorToUse"
  #   }
  #   else {
  #     #{ Fallback to universal editor
  #     $fallbackEditor = if ($IsWindows -or $env:OS -like "*Windows*") { 'notepad' } else { 'nano' }
  #     if ($Scope -eq 'Process') {
  #       $env:EDITOR = $fallbackEditor
  #     }
  #     else {
  #       [System.Environment]::SetEnvironmentVariable('EDITOR', $fallbackEditor, $Scope)
  #     }
  #     Write-Pretty -Tag "Debug" -Scope "Name" "EDITOR => $fallbackEditor (fallback)'
  #   }

  #   # Clear VISUAL in TUI-only environments
  #   Write-Pretty -Tag 'Export" "VISUAL not set (TUI-only environment)"
  #   if ($Scope -eq 'Process') {
  #     Remove-Item "env:VISUAL" -ErrorAction SilentlyContinue
  #   }
  #   else {
  #     [System.Environment]::SetEnvironmentVariable('VISUAL', $null, $Scope)
  #   }
  # }
}

function Initialize-EditorEnvironment {
  <#
    .SYNOPSIS
    Complete editor environment initialization

    .DESCRIPTION
    Performs full editor environment setup including:
    - Editor preference detection and caching
    - Standard environment variable export
    - Configuration validation

    This is typically called once during profile/script initialization.

    .PARAMETER ExportScope
    Scope for environment variable export (Process, User, Machine)

    .PARAMETER Force
    Force re-initialization even if already configured
    #>
  [CmdletBinding()]
  param(
    [ValidateSet('Process', 'User', 'Machine')]
    [string]$ExportScope = 'Process',
    [switch]$Force
  )

  #{ Initialize editor selection
  $EditorConfig.CurrentEditor = Get-PreferredEditor -Force $Force

  #{ Export standard environment variables
  Export-EditorVariables -Scope $ExportScope

  Write-Pretty -Tag 'Verbose' -Scope 'Name' 'Editor environment initialized successfully'
}

#endregion

#region Initialization

# Initialize with intelligent editor selection and export environment variables
Initialize-EditorEnvironment

# Create alias for easy editor launching
Set-Alias -Name 'edit' -Value 'Invoke-Editor' -Description 'Quick editor launcher - opens current directory or specified files/paths'

# Export main functions for use in other scripts
Export-ModuleMember -Function @(
  'Get-PreferredEditor',
  'Get-AvailableEditor',
  'Set-PreferredEditor',
  'Get-Editor',
  'Set-Editor',
  'Invoke-Editor',
  'Show-EditorConfig',
  'Set-EditorPreference',
  'Test-GuiEnvironment',
  'Export-EditorVariables',
  'Initialize-EditorEnvironment'
) -Alias @('edit')

#endregion
