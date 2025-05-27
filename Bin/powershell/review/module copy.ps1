<#
.SYNOPSIS
    Unified PowerShell module management utility.
.DESCRIPTION
    Provides a single interface for managing PowerShell modules:
    - Installing and importing modules (local or from PSGallery)
    - Removing modules from current session
    - Completely purging modules from the system
    - Querying module information
.PARAMETER Name
    One or more module names to manage. Accepts pipeline input.
.PARAMETER Install
    Installs (if needed) and imports the module. Uses local version if -Local is specified.
.PARAMETER Update
    Updates the module to the latest version from PSGallery and imports it.
.PARAMETER Remove
    Removes the module from the current session only.
.PARAMETER Purge
    Completely removes the module from the system (all versions).
.PARAMETER Local
    When used with -Install, checks local dotfiles modules before PSGallery.
.PARAMETER Detailed
    When querying module info (default mode), shows additional details like Path and Description.
.EXAMPLE
    Invoke-Module Terminal-Icons
    # Installs (if needed) and imports Terminal-Icons from PSGallery

.EXAMPLE
    Invoke-Module Terminal-Icons -Install
    # Same as above - explicit install and import

.EXAMPLE
    Invoke-Module PSScriptAnalyzer -Local
    # Uses local version if available, otherwise installs from PSGallery

.EXAMPLE
    Invoke-Module Terminal-Icons -Update
    # Updates Terminal-Icons to latest version and imports it

.EXAMPLE
    Invoke-Module Terminal-Icons -Remove
    # Removes Terminal-Icons from current session

.EXAMPLE
    Invoke-Module Terminal-Icons -Purge
    # Completely removes Terminal-Icons from the system

.EXAMPLE
    Get-Module -ListAvailable | Invoke-Module -Info
    # Shows basic info (Name, Version) for all available modules

.EXAMPLE
    Invoke-Module PSScriptAnalyzer,Terminal-Icons -Info -Detailed
    # Shows detailed info for multiple modules

.EXAMPLE
    Get-ChildItem $env:DOTS_MOD_PS -Directory | Invoke-Module -Detailed
    # Shows info for all local modules

.EXAMPLE
    Invoke-Module Term*
    # Shows info for modules matching wildcard
#>
function Invoke-Module {
    [CmdletBinding(DefaultParameterSetName = 'Install')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('ModuleName', 'Name')]
        [string[]]$InputObject,

        [Parameter(ParameterSetName = 'Install')]
        [switch]$Install,

        [Parameter(ParameterSetName = 'Update')]
        [switch]$Update,

        [Parameter(ParameterSetName = 'Remove')]
        [switch]$Remove,

        [Parameter(ParameterSetName = 'Purge')]
        [switch]$Purge,

        [Parameter(ParameterSetName = 'Install')]
        [switch]$Local,

        [Parameter(ParameterSetName = 'Info')]
        [Alias('d')]
        [switch]$Detailed,

        [Parameter(ParameterSetName = 'Info')]
        [switch]$Info
    )

    begin {
        Write-Verbose "Starting Invoke-Module with parameter set: $($PSCmdlet.ParameterSetName)"

        # Check if DOTS_MOD_PS environment variable exists when using -Local
        if ($Local -and -not $env:DOTS_MOD_PS) {
            Write-Warning "DOTS_MOD_PS environment variable is not set. -Local option will be ignored."
        }
    }

    process {
        foreach ($moduleName in $InputObject) {
            # Handle directory objects from Get-ChildItem
            if ($moduleName -is [System.IO.DirectoryInfo]) {
                $moduleName = $moduleName.Name
            }

            Write-Verbose "Processing module: $moduleName"

            switch ($PSCmdlet.ParameterSetName) {
                'Install' {
                    Write-Debug "Processing Install for module: $moduleName"

                    # Try local first if requested
                    if ($Local -and $env:DOTS_MOD_PS) {
                        $localPath = Join-Path $env:DOTS_MOD_PS $moduleName
                        if (Test-Path -Path $localPath -PathType Container) {
                            Write-Verbose "Found local module at: $localPath"
                            try {
                                Import-Module $localPath -Force -ErrorAction Stop
                                Write-Verbose "Successfully imported local module: $moduleName"
                                continue
                            }
                            catch {
                                Write-Warning "Failed to import local module '$moduleName': $($_.Exception.Message)"
                                Write-Debug "Falling back to PSGallery installation"
                            }
                        }
                        else {
                            Write-Debug "Local module path not found: $localPath"
                        }
                    }

                    # Check if module is already available locally
                    $existingModule = Get-Module -ListAvailable -Name $moduleName -ErrorAction SilentlyContinue |
                    Sort-Object @{Expression = { [version]$_.Version }; Descending = $true } |
                    Select-Object -First 1

                    if ($existingModule) {
                        Write-Verbose "Module '$moduleName' (v$($existingModule.Version)) found locally, importing..."
                        try {
                            Import-Module $moduleName -Force -ErrorAction Stop
                            Write-Debug "Successfully imported existing module: $moduleName"
                            continue
                        }
                        catch {
                            Write-Error "Failed to import existing module '$moduleName': $($_.Exception.Message)"
                            continue
                        }
                    }

                    # Module not found locally, install from PSGallery
                    Write-Verbose "Module '$moduleName' not found locally, installing from PSGallery..."
                    try {
                        Install-Module -Name $moduleName -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                        Write-Verbose "Successfully installed: $moduleName"
                    }
                    catch {
                        Write-Error "Failed to install module '$moduleName': $($_.Exception.Message)"
                        continue
                    }

                    # Import the newly installed module
                    try {
                        Import-Module $moduleName -Force -ErrorAction Stop
                        Write-Debug "Successfully imported newly installed module: $moduleName"
                    }
                    catch {
                        Write-Error "Failed to import module '$moduleName': $($_.Exception.Message)"
                    }
                }

                'Update' {
                    Write-Debug "Processing Update for module: $moduleName"

                    # Check if module is currently installed
                    $installedModule = Get-InstalledModule -Name $moduleName -ErrorAction SilentlyContinue
                    if (-not $installedModule) {
                        Write-Warning "Module '$moduleName' is not installed via PowerShellGet. Use -Install instead."
                        continue
                    }

                    # Check for available updates
                    try {
                        $onlineModule = Find-Module -Name $moduleName -ErrorAction Stop
                        $currentVersion = [version]$installedModule.Version
                        $latestVersion = [version]$onlineModule.Version

                        if ($latestVersion -gt $currentVersion) {
                            Write-Verbose "Updating '$moduleName' from v$currentVersion to v$latestVersion..."

                            # Remove from current session first
                            Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue

                            # Update the module
                            Update-Module -Name $moduleName -Force -ErrorAction Stop
                            Write-Verbose "Successfully updated: $moduleName"

                            # Import the updated module
                            Import-Module $moduleName -Force -ErrorAction Stop
                            Write-Debug "Successfully imported updated module: $moduleName"
                        }
                        else {
                            Write-Debug "Module '$moduleName' (v$currentVersion) is already up to date"
                            # Still import it if not loaded
                            if (-not (Get-Module -Name $moduleName)) {
                                Import-Module $moduleName -Force -ErrorAction Stop
                                Write-Debug "Imported current module: $moduleName"
                            }
                        }
                    }
                    catch {
                        Write-Error "Failed to update module '$moduleName': $($_.Exception.Message)"
                    }
                }

                'Remove' {
                    Write-Debug "Processing Remove for module: $moduleName"
                    try {
                        $loadedModule = Get-Module -Name $moduleName -ErrorAction SilentlyContinue
                        if ($loadedModule) {
                            Remove-Module -Name $moduleName -Force -ErrorAction Stop
                            Write-Verbose "Removed '$moduleName' from current session"
                        }
                        else {
                            Write-Debug "Module '$moduleName' is not currently loaded"
                        }
                    }
                    catch {
                        Write-Error "Failed to remove module '$moduleName': $($_.Exception.Message)"
                    }
                }

                'Purge' {
                    Write-Debug "Processing Purge for module: $moduleName"

                    # First remove from current session
                    Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue

                    # Find and remove from all module paths
                    $removed = $false
                    $modulePaths = $env:PSModulePath -split [IO.Path]::PathSeparator

                    foreach ($basePath in $modulePaths) {
                        $fullPath = Join-Path $basePath $moduleName
                        if (Test-Path $fullPath) {
                            try {
                                Remove-Item -Path $fullPath -Recurse -Force -ErrorAction Stop
                                Write-Debug "Removed module directory: $fullPath"
                                $removed = $true
                            }
                            catch {
                                Write-Warning "Failed to remove directory '$fullPath': $($_.Exception.Message)"
                            }
                        }
                    }

                    # Try to uninstall via PowerShellGet
                    try {
                        $installedModules = Get-InstalledModule -Name $moduleName -AllVersions -ErrorAction SilentlyContinue
                        if ($installedModules) {
                            Uninstall-Module -Name $moduleName -AllVersions -Force -ErrorAction Stop
                            Write-Verbose "Successfully purged module via PowerShellGet: $moduleName"
                            $removed = $true
                        }
                    }
                    catch {
                        Write-Debug "PowerShellGet uninstall failed for '$moduleName': $($_.Exception.Message)"
                    }

                    if ($removed) {
                        Write-Verbose "Module '$moduleName' has been purged"
                    }
                    else {
                        Write-Warning "No installed instances of '$moduleName' were found to remove"
                    }
                }

                'Info' {
                    # Get module information with wildcard support
                    $modules = Get-Module -Name $moduleName -ListAvailable -ErrorAction SilentlyContinue |
                    Sort-Object Name, @{Expression = { [version]$_.Version }; Descending = $true } |
                    Group-Object Name |
                    ForEach-Object { $_.Group | Select-Object -First 1 }

                    if (-not $modules) {
                        Write-Warning "No modules found matching: $moduleName"
                        continue
                    }

                    foreach ($module in $modules) {
                        if ($Detailed) {
                            [PSCustomObject]@{
                                Name        = $module.Name
                                Version     = $module.Version
                                Path        = $module.ModuleBase
                                Description = $module.Description
                                Author      = $module.Author
                                CompanyName = $module.CompanyName
                            } | Format-List
                        }
                        else {
                            [PSCustomObject]@{
                                Name    = $module.Name
                                Version = $module.Version
                            }
                        }
                    }
                }
            }
        }
    }

    end {
        Write-Verbose "Invoke-Module completed"
    }
}

# Create aliases for convenience
Set-Alias -Name imod -Value Invoke-Module
Set-Alias -Name mod -Value Invoke-Module

Export-ModuleMember -Function Invoke-Module -Alias imod, mod
