function Import-Script {
    <#
    .SYNOPSIS
    Imports scripts or folders from a specified root path with flexible loading logic.

    .DESCRIPTION
    For each item in the list:
    - If the item ends with '.ps1', treat it as an explicit script path and load directly.
    - Otherwise, treat it as a folder name under the current root path:
        - If the folder contains a _.ps1 file, load that file.
        - Otherwise, load all .ps1 files in that folder.
    - If the folder does not exist, look for a script file named <item>.ps1 in the current root path and load it if found.
    When dot-sourcing scripts, nested Import-Script calls will use the directory of the calling script as the default root.
    Writes verbose output on success, warnings if files/folders are missing, and errors if loading fails.

    .PARAMETER ScriptItems
    An ordered array of folder names or script file base names to import.

    .PARAMETER RootPath
    The root directory path where the script files are located.
    - If not specified, automatically uses the directory of the calling script
    - Use this parameter to explicitly specify a different starting directory
    - Useful for loading scripts from a different location than the caller's directory

    .EXAMPLE
    # Load scripts from the same directory as the calling script (automatic detection)
    Import-Script -ScriptItems @('output', 'command', 'context')

    .EXAMPLE
    # Load scripts from a specific directory
    Import-Script -ScriptItems @('utils', 'helpers') -RootPath 'C:\MyScripts\Common'

    .EXAMPLE
    # Load scripts from a relative path
    Import-Script -ScriptItems @('shared') -RootPath '..\SharedModules'
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$ScriptItems,

        [string]$RootPath
    )

    # If no RootPath provided, determine it from the calling script
    if (-not $RootPath) {
        $callingScript = (Get-PSCallStack)[1].ScriptName
        if ($callingScript) {
            $RootPath = Split-Path -Parent $callingScript
        } else {
            $RootPath = $PSScriptRoot
        }
    }

    foreach ($item in $ScriptItems) {
        # If item ends with '.ps1', treat as explicit path and load directly
        if ($item -like '*.ps1') {
            $explicitPath = if ([System.IO.Path]::IsPathRooted($item)) {
                $item
            }
            else {
                Join-Path $RootPath $item
            }

            if (Test-Path $explicitPath) {
                try {
                    . $explicitPath
                    Write-Verbose "Initialized script: $explicitPath"
                }
                catch {
                    Write-Error "Failed to load $explicitPath`: $_"
                }
            }
            else {
                Write-Warning "Explicit script file not found: $explicitPath"
            }
            continue
        }

        # Otherwise, treat as folder or script base name
        $folderPath = Join-Path $RootPath $item
        $fileInFolder = Join-Path $folderPath '_.ps1'
        $fileAtRoot = Join-Path $RootPath "$item.ps1"

        if (Test-Path $folderPath -PathType Container) {
            if (Test-Path $fileInFolder) {
                try {
                    . $fileInFolder
                    Write-Verbose "Initialized script: $item\_.ps1"
                }
                catch {
                    Write-Error "Failed to load $item\_.ps1`: $_"
                }
            }
            else {
                $ps1Files = Get-ChildItem -Path $folderPath -Filter '*.ps1' -File | Sort-Object Name
                if ($ps1Files.Count -gt 0) {
                    foreach ($file in $ps1Files) {
                        try {
                            . $file.FullName
                            Write-Verbose "Initialized script: $($item)\$($file.Name)"
                            Write-Host "[TRACE] Initialized script: $($item)\$($file.Name)"
                        }
                        catch {
                            Write-Error "Failed to load $($file.Name): $_"
                            Write-Host "[ERROR] Failed to load $($file.Name): $_"
                        }
                    }
                }
                else {
                    Write-Warning "No scripts found in folder: $folderPath"
                    Write-Host "[WARN] No scripts found in folder: $folderPath"
                }
            }
        }
        elseif (Test-Path $fileAtRoot) {
            try {
                . $fileAtRoot
                Write-Verbose "Initialized script: $item.ps1"
                Write-Host "[TRACE] Initialized script: $item.ps1"
            }
            catch {
                Write-Error "Failed to load $item.ps1`: $_"
                Write-Host "[TRACE] Failed to load $item.ps1`: $_"
            }
        }
        else {
            Write-Warning "Neither folder nor script file found for: $item"
            Write-Host "[TRACE] Neither folder nor script file found for: $item"
        }
    }
}

function Test-ImportScript {
    <#
    .SYNOPSIS
    Comprehensive test suite for the Import-Script function.

    .DESCRIPTION
    Tests various scenarios including:
    - Automatic root path detection
    - Explicit root path specification
    - Folder with _.ps1 files
    - Folder with multiple .ps1 files
    - Direct .ps1 file loading
    - Nested Import-Script calls
    - Error handling for missing files/folders
    - Relative and absolute path handling

    .PARAMETER TestDirectory
    Base directory where test files will be created. Defaults to a temp directory.

    .PARAMETER CleanupAfter
    Whether to cleanup test files after running tests. Defaults to $true.
    #>
    param(
        [string]$TestDirectory = (Join-Path $env:TEMP "ImportScriptTests"),
        [bool]$CleanupAfter = $true
    )

    Write-Host "=== Import-Script Test Suite ===" -ForegroundColor Cyan
    Write-Host "Test Directory: $TestDirectory" -ForegroundColor Gray

    $testResults = @()

    function Add-TestResult {
        param($TestName, $Passed, $Message = "")
        $testResults += [PSCustomObject]@{
            Test = $TestName
            Passed = $Passed
            Message = $Message
        }
        $color = if ($Passed) { "Green" } else { "Red" }
        $status = if ($Passed) { "PASS" } else { "FAIL" }
        Write-Host "[$status] $TestName" -ForegroundColor $color
        if ($Message) { Write-Host "  $Message" -ForegroundColor Gray }
    }

    try {
        # Setup test directory structure
        Write-Host "`nSetting up test environment..." -ForegroundColor Yellow

        if (Test-Path $TestDirectory) {
            Remove-Item $TestDirectory -Recurse -Force
        }
        New-Item -ItemType Directory -Path $TestDirectory -Force | Out-Null

        # Create test structure
        $baseDir = Join-Path $TestDirectory "Base"
        $outputDir = Join-Path $baseDir "output"
        $utilsDir = Join-Path $baseDir "utils"
        $sharedDir = Join-Path $TestDirectory "Shared"

        New-Item -ItemType Directory -Path $baseDir -Force | Out-Null
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        New-Item -ItemType Directory -Path $utilsDir -Force | Out-Null
        New-Item -ItemType Directory -Path $sharedDir -Force | Out-Null

        # Create test files
        @"
# Base main script
`$global:TestResults = @()
`$global:TestResults += 'base-main'
Import-Script @('output', 'utils', 'standalone.ps1')
"@ | Out-File (Join-Path $baseDir "main.ps1") -Encoding UTF8

        @"
# Base standalone script
`$global:TestResults += 'base-standalone'
"@ | Out-File (Join-Path $baseDir "standalone.ps1") -Encoding UTF8

        @"
# Output folder main script
`$global:TestResults += 'output-main'
Import-Script @('verbosity', 'pattern')
"@ | Out-File (Join-Path $outputDir "_.ps1") -Encoding UTF8

        @"
# Output verbosity script
`$global:TestResults += 'output-verbosity'
"@ | Out-File (Join-Path $outputDir "verbosity.ps1") -Encoding UTF8

        @"
# Output pattern script
`$global:TestResults += 'output-pattern'
"@ | Out-File (Join-Path $outputDir "pattern.ps1") -Encoding UTF8

        @"
# Utils script 1
`$global:TestResults += 'utils-script1'
"@ | Out-File (Join-Path $utilsDir "script1.ps1") -Encoding UTF8

        @"
# Utils script 2
`$global:TestResults += 'utils-script2'
"@ | Out-File (Join-Path $utilsDir "script2.ps1") -Encoding UTF8

        @"
# Shared module
`$global:TestResults += 'shared-module'
"@ | Out-File (Join-Path $sharedDir "module.ps1") -Encoding UTF8

        Write-Host "Test environment ready." -ForegroundColor Green

        # Test 1: Automatic root path detection
        Write-Host "`nRunning tests..." -ForegroundColor Yellow
        try {
            $global:TestResults = @()
            Push-Location $baseDir
            . (Join-Path $baseDir "main.ps1")
            Pop-Location

            $expected = @('base-main', 'output-main', 'output-verbosity', 'output-pattern', 'utils-script1', 'utils-script2', 'base-standalone')
            $allFound = $true
            $missing = @()
            foreach ($exp in $expected) {
                if ($exp -notin $global:TestResults) {
                    $allFound = $false
                    $missing += $exp
                }
            }
            Add-TestResult "Automatic root path detection with nested calls" $allFound "Missing: $($missing -join ', ')"
        }
        catch {
            Add-TestResult "Automatic root path detection with nested calls" $false $_.Exception.Message
        }

        # Test 2: Explicit root path - absolute
        try {
            $global:TestResults = @()
            Import-Script -ScriptItems @('module.ps1') -RootPath $sharedDir
            $passed = 'shared-module' -in $global:TestResults
            Add-TestResult "Explicit absolute root path" $passed
        }
        catch {
            Add-TestResult "Explicit absolute root path" $false $_.Exception.Message
        }

        # Test 3: Explicit root path - relative
        try {
            $global:TestResults = @()
            Push-Location $TestDirectory
            Import-Script -ScriptItems @('module.ps1') -RootPath 'Shared'
            Pop-Location
            $passed = 'shared-module' -in $global:TestResults
            Add-TestResult "Explicit relative root path" $passed
        }
        catch {
            Add-TestResult "Explicit relative root path" $false $_.Exception.Message
        }

        # Test 4: Folder with _.ps1 file
        try {
            $global:TestResults = @()
            Import-Script -ScriptItems @('output') -RootPath $baseDir
            $passed = 'output-main' -in $global:TestResults -and 'output-verbosity' -in $global:TestResults
            Add-TestResult "Folder with _.ps1 file" $passed
        }
        catch {
            Add-TestResult "Folder with _.ps1 file" $false $_.Exception.Message
        }

        # Test 5: Folder with multiple .ps1 files (no _.ps1)
        try {
            $global:TestResults = @()
            Import-Script -ScriptItems @('utils') -RootPath $baseDir
            $passed = 'utils-script1' -in $global:TestResults -and 'utils-script2' -in $global:TestResults
            Add-TestResult "Folder with multiple .ps1 files" $passed
        }
        catch {
            Add-TestResult "Folder with multiple .ps1 files" $false $_.Exception.Message
        }

        # Test 6: Direct .ps1 file loading
        try {
            $global:TestResults = @()
            Import-Script -ScriptItems @('standalone.ps1') -RootPath $baseDir
            $passed = 'base-standalone' -in $global:TestResults
            Add-TestResult "Direct .ps1 file loading" $passed
        }
        catch {
            Add-TestResult "Direct .ps1 file loading" $false $_.Exception.Message
        }

        # Test 7: Mixed loading types
        try {
            $global:TestResults = @()
            Import-Script -ScriptItems @('output', 'standalone.ps1', 'utils') -RootPath $baseDir
            $expected = @('output-main', 'output-verbosity', 'output-pattern', 'base-standalone', 'utils-script1', 'utils-script2')
            $allFound = $expected | ForEach-Object { $_ -in $global:TestResults } | Where-Object { $_ -eq $false } | Measure-Object | Select-Object -ExpandProperty Count
            Add-TestResult "Mixed loading types" ($allFound -eq 0)
        }
        catch {
            Add-TestResult "Mixed loading types" $false $_.Exception.Message
        }

        # Test 8: Error handling - missing folder
        try {
            $warningCount = 0
            $oldWarningPreference = $WarningPreference
            $WarningPreference = 'Continue'
            Import-Script -ScriptItems @('nonexistent') -RootPath $baseDir -WarningAction SilentlyContinue -WarningVariable warnings
            $WarningPreference = $oldWarningPreference
            $passed = $warnings.Count -gt 0
            Add-TestResult "Error handling - missing folder" $passed "Warnings generated: $($warnings.Count)"
        }
        catch {
            Add-TestResult "Error handling - missing folder" $false $_.Exception.Message
        }

        # Test 9: Error handling - missing script file
        try {
            $warningCount = 0
            $oldWarningPreference = $WarningPreference
            $WarningPreference = 'Continue'
            Import-Script -ScriptItems @('missing.ps1') -RootPath $baseDir -WarningAction SilentlyContinue -WarningVariable warnings
            $WarningPreference = $oldWarningPreference
            $passed = $warnings.Count -gt 0
            Add-TestResult "Error handling - missing script file" $passed "Warnings generated: $($warnings.Count)"
        }
        catch {
            Add-TestResult "Error handling - missing script file" $false $_.Exception.Message
        }

        # Test 10: Absolute path for script items
        try {
            $global:TestResults = @()
            $absoluteScript = Join-Path $sharedDir "module.ps1"
            Import-Script -ScriptItems @($absoluteScript) -RootPath $baseDir
            $passed = 'shared-module' -in $global:TestResults
            Add-TestResult "Absolute path for script items" $passed
        }
        catch {
            Add-TestResult "Absolute path for script items" $false $_.Exception.Message
        }

    }
    finally {
        # Cleanup
        if ($CleanupAfter -and (Test-Path $TestDirectory)) {
            Write-Host "`nCleaning up test files..." -ForegroundColor Yellow
            Remove-Item $TestDirectory -Recurse -Force -ErrorAction SilentlyContinue
        }

        # Remove global test variable
        if (Get-Variable -Name TestResults -Scope Global -ErrorAction SilentlyContinue) {
            Remove-Variable -Name TestResults -Scope Global
        }
    }

    # Summary
    Write-Host "`n=== Test Results Summary ===" -ForegroundColor Cyan
    $passed = ($testResults | Where-Object { $_.Passed }).Count
    $total = $testResults.Count
    $failed = $total - $passed

    Write-Host "Total Tests: $total" -ForegroundColor White
    Write-Host "Passed: $passed" -ForegroundColor Green
    Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })

    if ($failed -gt 0) {
        Write-Host "`nFailed Tests:" -ForegroundColor Red
        $testResults | Where-Object { -not $_.Passed } | ForEach-Object {
            Write-Host "  - $($_.Test): $($_.Message)" -ForegroundColor Red
        }
    }

    Write-Host "`nOverall Result: $(if ($failed -eq 0) { 'SUCCESS' } else { 'FAILURE' })" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })

    return $testResults
}

Export-ModuleMember `
  -Function @(
  'Import-Script'
) `
  -Alias @(
)
