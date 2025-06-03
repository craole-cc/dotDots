function Invoke-Module {
    [CmdletBinding(DefaultParameterSetName = 'Install')]
    param(

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
        [switch]$Info,

        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('ModuleName', 'Name')]
        [string[]]$InputObject
    )

    begin {
        Write-Pretty `
        -Tag "Debug" `
        -Scope "Name" `
        -NoNewLine `
        "Parameter Set => $($PSCmdlet.ParameterSetName)"

        #{ Check if DOTS_MOD_PS environment variable exists when using -Local
        if ($Local -and -not $env:DOTS_MOD_PS) {
            Write-Warning "DOTS_MOD_PS environment variable is not set. -Local option will be ignored."
        }

        # Helper function to find modules in all PSModulePath locations
        function Find-AllModules {
            param([string]$ModuleName)

            $foundModules = @()
            $modulePaths = $env:PSModulePath -split [IO.Path]::PathSeparator

            foreach ($basePath in $modulePaths) {
                if (-not (Test-Path $basePath)) { continue }

                #{ Look for exact match first
                $moduleDir = Join-Path $basePath $ModuleName
                if (Test-Path $moduleDir -PathType Container) {
                    $moduleFiles = @()

                    #{ Look for module manifest first (.psd1)
                    $manifestPath = Join-Path $moduleDir "$ModuleName.psd1"
                    if (Test-Path $manifestPath) {
                        $moduleFiles += Get-Item $manifestPath
                    }

                    #{ Look for module script (.psm1)
                    $scriptPath = Join-Path $moduleDir "$ModuleName.psm1"
                    if (Test-Path $scriptPath) {
                        $moduleFiles += Get-Item $scriptPath
                    }

                    #{ Look for any .psm1 files in the directory
                    $psmFiles = Get-ChildItem -Path $moduleDir -Filter "*.psm1" -ErrorAction SilentlyContinue
                    if ($psmFiles) {
                        $moduleFiles += $psmFiles
                    }

                    #{ Create module info objects
                    foreach ($file in $moduleFiles) {
                        try {
                            if ($file.Extension -eq '.psd1') {
                                #{ Try to parse manifest
                                $manifest = Import-PowerShellDataFile -Path $file.FullName -ErrorAction SilentlyContinue
                                if ($manifest) {
                                    $foundModules += [PSCustomObject]@{
                                        Name        = $ModuleName
                                        Version     = $manifest.ModuleVersion -as [version] ?? [version]"1.0.0"
                                        Path        = $file.DirectoryName
                                        ModuleBase  = $file.DirectoryName
                                        Description = $manifest.Description
                                        Author      = $manifest.Author
                                        CompanyName = $manifest.CompanyName
                                        ModuleType  = 'Manifest'
                                        FullPath    = $file.FullName
                                    }
                                }
                            }
                            elseif ($file.Extension -eq '.psm1') {
                                $foundModules += [PSCustomObject]@{
                                    Name        = $ModuleName
                                    Version     = [version]"1.0.0"
                                    Path        = $file.DirectoryName
                                    ModuleBase  = $file.DirectoryName
                                    Description = "PowerShell module"
                                    Author      = ""
                                    CompanyName = ""
                                    ModuleType  = 'Script'
                                    FullPath    = $file.FullName
                                }
                            }
                        }
                        catch {
                            Write-Pretty -Tag "Error" "Failed to process module file '$($file.FullName)': $($_.Exception.Message)"
                        }
                    }
                }

                #{ Also check for wildcard matches if ModuleName contains wildcards
                if ($ModuleName -like '*[*?]*') {
                    try {
                        $matchingDirs = Get-ChildItem -Path $basePath -Directory -Name $ModuleName -ErrorAction SilentlyContinue
                        foreach ($dirName in $matchingDirs) {
                            $dirPath = Join-Path $basePath $dirName
                            $manifestPath = Join-Path $dirPath "$dirName.psd1"
                            $scriptPath = Join-Path $dirPath "$dirName.psm1"

                            if (Test-Path $manifestPath) {
                                try {
                                    $manifest = Import-PowerShellDataFile -Path $manifestPath -ErrorAction SilentlyContinue
                                    if ($manifest) {
                                        $foundModules += [PSCustomObject]@{
                                            Name        = $dirName
                                            Version     = $manifest.ModuleVersion -as [version] ?? [version]"1.0.0"
                                            Path        = $dirPath
                                            ModuleBase  = $dirPath
                                            Description = $manifest.Description
                                            Author      = $manifest.Author
                                            CompanyName = $manifest.CompanyName
                                            ModuleType  = 'Manifest'
                                            FullPath    = $manifestPath
                                        }
                                    }
                                }
                                catch {
                                    Write-Pretty -Tag "Error" "Failed to process manifest '$manifestPath': $($_.Exception.Message)"
                                }
                            }
                            elseif (Test-Path $scriptPath) {
                                $foundModules += [PSCustomObject]@{
                                    Name        = $dirName
                                    Version     = [version]"1.0.0"
                                    Path        = $dirPath
                                    ModuleBase  = $dirPath
                                    Description = "PowerShell module"
                                    Author      = ""
                                    CompanyName = ""
                                    ModuleType  = 'Script'
                                    FullPath    = $scriptPath
                                }
                            }
                        }
                    }
                    catch {
                        Write-Pretty -Tag "Error" "Failed while searching by wildcard in '$basePath': $($_.Exception.Message)"
                    }
                }
            }

            return $foundModules
        }
    }

    process {
        foreach ($moduleName in $InputObject) {
            #{ Handle directory objects from Get-ChildItem
            if ($moduleName -is [System.IO.DirectoryInfo]) {
                $moduleName = $moduleName.Name
                Write-Pretty -Tag "Verbose"  "Processing module: $moduleName"
            }

            switch ($PSCmdlet.ParameterSetName) {
                'Install' {
                    Write-Pretty -Tag "Verbose"  "Installing for module: $moduleName"

                    #{ Try local first if requested
                    if ($Local -and $env:DOTS_MOD_PS) {
                        $localPath = Join-Path $env:DOTS_MOD_PS $moduleName
                        if (Test-Path -Path $localPath -PathType Container) {
                            Write-Pretty -Tag "Verbose"  "Found local module at: $localPath"
                            try {
                                Import-Module $localPath -Force -ErrorAction Stop
                                Write-Pretty -Tag "Verbose"  "Successfully imported local module: $moduleName"
                                continue
                            }
                            catch {
                                Write-Pretty -Tag "Warning" "Failed to import local module '$moduleName': $($_.Exception.Message)"
                                Write-Pretty -Tag "Verbose"  "Falling back to PSGallery installation"
                            }
                        }
                        else {
                            Write-Pretty -Tag "Warning" "Local module path not found: $localPath"
                        }
                    }

                    #{ Check if module is already available locally using both standard and custom search
                    $existingModule = Get-Module -ListAvailable -Name $moduleName -ErrorAction SilentlyContinue |
                    Sort-Object @{Expression = { [version]$_.Version }; Descending = $true } |
                    Select-Object -First 1

                    # @If not found via Get-Module, try our custom search
                    if (-not $existingModule) {
                        $customModules = Find-AllModules -ModuleName $moduleName
                        if ($customModules) {
                            $existingModule = $customModules | Sort-Object @{Expression = { $_.Version }; Descending = $true } | Select-Object -First 1
                            Write-Pretty -Tag "Verbose"  "Found module via custom search: $($existingModule.Name) at $($existingModule.Path)"
                        }
                    }

                    if ($existingModule) {
                        Write-Pretty -Tag "Verbose"  "Module '$moduleName' (v$($existingModule.Version)) found locally, importing..."
                        try {
                            #{ Use the full path if available for custom modules
                            if ($existingModule.FullPath -and $existingModule.ModuleType) {
                                Import-Module $existingModule.Path -Force -ErrorAction Stop
                            }
                            else {
                                Import-Module $moduleName -Force -ErrorAction Stop
                            }
                            Write-Debug "Successfully imported existing module: $moduleName"
                            continue
                        }
                        catch {
                            Write-Error "Failed to import existing module '$moduleName': $($_.Exception.Message)"
                            continue
                        }
                    }

                    #{ Module not found locally, install from PSGallery
                    Write-Pretty -Tag "Verbose"  "Module '$moduleName' not found locally, installing from PSGallery..."
                    try {
                        Install-Module -Name $moduleName -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                        Write-Pretty -Tag "Verbose"  "Successfully installed: $moduleName"
                    }
                    catch {
                        Write-Error "Failed to install module '$moduleName': $($_.Exception.Message)"
                        continue
                    }

                    #{ Import the newly installed module
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

                    #{ Check if module is currently installed
                    $installedModule = Get-InstalledModule -Name $moduleName -ErrorAction SilentlyContinue
                    if (-not $installedModule) {
                        Write-Warning "Module '$moduleName' is not installed via PowerShellGet. Use -Install instead."
                        continue
                    }

                    #{ Check for available updates
                    try {
                        $onlineModule = Find-Module -Name $moduleName -ErrorAction Stop
                        $currentVersion = [version]$installedModule.Version
                        $latestVersion = [version]$onlineModule.Version

                        if ($latestVersion -gt $currentVersion) {
                            Write-Pretty -Tag "Verbose"  "Updating '$moduleName' from v$currentVersion to v$latestVersion..."

                            #{ Remove from current session first
                            Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue

                            #{ Update the module
                            Update-Module -Name $moduleName -Force -ErrorAction Stop
                            Write-Pretty -Tag "Verbose"  "Updated: $moduleName"

                            #{ Import the updated module
                            Import-Module $moduleName -Force -ErrorAction Stop
                        }
                        else {
                            Write-Pretty -Tag "Verbose" "Module '$moduleName' (v$currentVersion) is already up to date"

                            #{ Still import it if not loaded
                            if (-not (Get-Module -Name $moduleName)) {
                                Import-Module $moduleName -Force -ErrorAction Stop
                            }
                        }

                        Write-Pretty -Tag "Debug"  "Imported module: $moduleName"
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
                            Write-Pretty -Tag "Verbose"  "Removed '$moduleName' from current session"
                        }
                        else {
                            Write-Pretty -Tag "Debug"  "Module '$moduleName' is not currently loaded"
                        }
                    }
                    catch {
                        Write-Pretty -Tag "Error"  "Failed to remove module '$moduleName': $($_.Exception.Message)"
                    }
                }

                'Purge' {
                    Write-Pretty -Tag "Verbose" "Processing Purge for module: $moduleName"

                    #{ First remove from current session
                    Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue

                    #{ Find and remove from all module paths
                    $removed = $false
                    $modulePaths = $env:PSModulePath -split [IO.Path]::PathSeparator

                    foreach ($basePath in $modulePaths) {
                        $fullPath = Join-Path $basePath $moduleName
                        if (Test-Path $fullPath) {
                            try {
                                Remove-Item -Path $fullPath -Recurse -Force -ErrorAction Stop
                                Write-Pretty -Tag "Debug" "Removed module directory: $fullPath"
                                $removed = $true
                            }
                            catch {
                                Write-Pretty -Tag "Error" "Failed to remove directory '$fullPath': $($_.Exception.Message)"
                            }
                        }
                    }

                    #{ Try to uninstall via PowerShellGet
                    try {
                        $installedModules = Get-InstalledModule -Name $moduleName -AllVersions -ErrorAction SilentlyContinue
                        if ($installedModules) {
                            Uninstall-Module -Name $moduleName -AllVersions -Force -ErrorAction Stop
                            Write-Pretty -Tag "Verbose"  "Purged module via PowerShellGet: $moduleName"
                            $removed = $true
                        }
                    }
                    catch {
                        Write-Pretty -Tag "Error" "PowerShellGet uninstall failed for '$moduleName': $($_.Exception.Message)"
                    }

                    if ($removed) {
                        Write-Pretty -Tag "Debug"  "Module '$moduleName' has been purged"
                    }
                    else {
                        Write-Pretty -Tag "Debug"  "No installed instances of '$moduleName' were found to remove"
                    }
                }

                'Info' {
                    #{ Get module information with wildcard support - try both methods
                    $modules = Get-Module -Name $moduleName -ListAvailable -ErrorAction SilentlyContinue

                    #{ If no modules found via standard method, try custom search
                    if (-not $modules) {
                        $customModules = Find-AllModules -ModuleName $moduleName
                        if ($customModules) {
                            $modules = $customModules
                        }
                    }

                    #{ Sort and deduplicate
                    $modules = $modules |
                    Sort-Object Name, @{Expression = { [version]$_.Version }; Descending = $true } |
                    Group-Object Name |
                    ForEach-Object { $_.Group | Select-Object -First 1 }

                    if (-not $modules) {
                        Write-Pretty -Tag "Warning"  "No modules found matching: $moduleName"
                        continue
                    }

                    foreach ($module in $modules) {
                        if ($Detailed) {
                            [PSCustomObject]@{
                                Name        = $module.Name
                                Version     = $module.Version
                                Path        = $module.ModuleBase ?? $module.Path
                                Description = $module.Description
                                Author      = $module.Author
                                CompanyName = $module.CompanyName
                                ModuleType  = $module.ModuleType ?? "Standard"
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
        Write-Pretty -Tag "Verbose"  "Invoke-Module completed on $InputObject"
    }
}

#{ Create aliases for convenience
Set-Alias -Name imod -Value Invoke-Module
Set-Alias -Name mod -Value Invoke-Module

Export-ModuleMember -Function Invoke-Module -Alias imod, mod
