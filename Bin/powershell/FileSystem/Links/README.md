# Links PowerShell Module

A comprehensive PowerShell module for managing symbolic links, hard links, and junctions on Windows systems.

## Module Structure

```ps1
Links/
├── Links.psd1     # Module manifest
├── Links.psm1     # Main module file
├── Private/                # Private helper functions
│   ├── Resolve-TargetPath.ps1
│   └── Test-CorrectLink.ps1
├── Public/                 # Public functions (exported)
│   ├── New-Link.ps1
│   ├── Test-Link.ps1
│   ├── Get-LinkReport.ps1
│   ├── New-SymbolicLink.ps1
│   ├── Backup-Links.ps1
│   ├── Restore-Links.ps1
│   ├── Repair-BrokenLinks.ps1
│   └── Remove-OrphanedLinks.ps1
└── README.md              # This file
```

## Installation

1. Create a new folder in your PowerShell modules directory:

   ```ps1
   $ModulePath = "$env:USERPROFILE\Documents\PowerShell\Modules\Links"
   New-Item -ItemType Directory -Path $ModulePath -Force
   ```

2. Copy all module files to the created directory, maintaining the folder structure.

3. Import the module:

   ```ps1
   Import-Module Links
   ```

## Functions Overview

### Core Functions

#### `New-Link`

Creates symbolic or hard links from source files to a target directory.

**Key Features:**

- Supports multiple source files and directories
- Filters by file types (default: .csv, .tsv)
- Handles existing files with optional prompting
- Supports recursive directory processing
- Backward compatibility with legacy parameters

**Examples:**

```powershell
# Create symbolic link for a single file
New-Link -Target "C:\neo4j\import" -Source "C:\data\users.csv"

# Create links for all CSV/TSV files in a directory
New-Link -Target "C:\neo4j\import" -Source "C:\data\csv-files" -Force

# Create hard links for specific file types
New-Link -Target "C:\output" -Source "C:\data" -FileTypes @('.txt', '.log') -Type Hard
```

#### `Test-Link`

Tests if a path is a link and returns detailed information about it.

**Returns:**

- `IsLink`: Boolean indicating if the path is any type of link
- `LinkType`: 'SymbolicLink', 'HardLink', 'Junction', or 'None'
- `Target`: The target path(s) the link points to
- `TargetExists`: Boolean indicating if the target exists
- `IsValid`: Boolean indicating if the link is valid

**Examples:**

```powershell
# Test a single path with output
Test-Link -Path "C:\data\mylink.csv"

# Test quietly and use result object
$linkInfo = Test-Link -Path "C:\data\mylink.csv" -Quiet
if ($linkInfo.IsLink) { Write-Host "This is a $($linkInfo.LinkType)" }
```

### Utility Functions

#### `Get-LinkReport`

Generates a comprehensive report of links in a directory tree.

```powershell
Get-LinkReport -Path "C:\MyData"
```

#### `New-SymbolicLink`

Creates symbolic links and validates their integrity after creation.

```powershell
New-SymbolicLink -Target "C:\links" -Source "C:\data\file.txt"
```

### Backup and Restore Functions

#### `Backup-Links`

Creates a backup of all links in a directory for later restoration.

```powershell
$backup = Backup-Links -Directory "C:\MyLinks"
```

#### `Restore-Links`

Restores links from a backup created by `Backup-Links`.

```powershell
Restore-Links -Backup $backup
```

### Maintenance Functions

#### `Repair-BrokenLinks`

Attempts to repair broken links by updating their targets to a new base path.

```powershell
# Preview what would be repaired
Repair-BrokenLinks -Directory "C:\Links" -NewBasePath "C:\NewData" -WhatIf

# Actually repair the links
Repair-BrokenLinks -Directory "C:\Links" -NewBasePath "C:\NewData"
```

#### `Remove-OrphanedLinks`

Removes orphaned (broken) links from a directory.

```powershell
# Preview what would be removed
Remove-OrphanedLinks -Directory "C:\Links" -WhatIf

# Actually remove orphaned links
Remove-OrphanedLinks -Directory "C:\Links"
```

## Common Usage Patterns

### Finding Broken Links

```powershell
# Find all broken links in a directory tree
Get-ChildItem "C:\data" -Recurse | Test-Link -Quiet | Where-Object { $_.IsLink -and -not $_.IsValid }
```

### Creating Links with Validation

```powershell
# Create links and validate them
$result = New-Link -Target "C:\backup" -Source "C:\important" -Force
if ($result.SuccessCount -gt 0) {
    Write-Host "Successfully linked $($result.SuccessCount) files"
}
```

### Comprehensive Link Management Workflow

```powershell
# 1. Create backup of existing links
$backup = Backup-Links -Directory "C:\MyLinks"

# 2. Generate initial report
Get-LinkReport -Path "C:\MyLinks"

# 3. Create new links
New-Link -Target "C:\MyLinks" -Source "C:\NewData" -Force

# 4. Repair any broken links
Repair-BrokenLinks -Directory "C:\MyLinks" -NewBasePath "C:\AlternateLocation"

# 5. Clean up orphaned links
Remove-OrphanedLinks -Directory "C:\MyLinks"

# 6. Generate final report
Get-LinkReport -Path "C:\MyLinks"
```

## Error Handling

The module includes comprehensive error handling:

- Validates source and target paths before processing
- Provides detailed error messages for failed operations
- Supports `-WhatIf` parameter for preview operations
- Returns summary objects with success/failure counts

## Requirements

- PowerShell 5.0 or later
- Windows operating system (for symbolic/hard link support)
- Appropriate permissions for creating links (may require administrator privileges)

## Notes

- Symbolic links may require administrator privileges on older Windows versions
- Hard links must be on the same volume as the source file
- The module includes fallback mechanisms for older PowerShell versions
- All functions support pipeline input where appropriate
