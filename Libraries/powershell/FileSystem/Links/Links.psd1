@{
  # Module manifest for Links
  RootModule        = 'Links.psm1'
  ModuleVersion     = '1.0.0'
  GUID              = '12345678-1234-1234-1234-123456789012'
  Author            = 'Craig ''Craole'' Cole'
  CompanyName       = 'Unknown'
  Copyright         = '(c) 2025. All rights reserved.'
  Description       = 'PowerShell module for managing symbolic and hard links'

  # Minimum version of the PowerShell engine required by this module
  PowerShellVersion = '5.0'

  # Functions to export from this module
  FunctionsToExport = @(
    'New-Link',
    'Test-Link',
    'Get-LinkReport',
    'New-SymbolicLink',
    'Backup-Links',
    'Restore-Links',
    'Repair-BrokenLinks',
    'Remove-OrphanedLinks'
  )

  # Cmdlets to export from this module
  CmdletsToExport   = @()

  # Variables to export from this module
  VariablesToExport = @()

  # Aliases to export from this module
  AliasesToExport   = @()

  # List of all files packaged with this module
  FileList          = @(
    'Links.psd1',
    'Links.psm1',
    'Internal\Resolve-TargetPath.ps1',
    'Internal\Test-CorrectLink.ps1',
    'External\New-Link.ps1',
    'External\Test-Link.ps1',
    'External\Get-LinkReport.ps1',
    'External\New-SymbolicLink.ps1',
    'External\Backup-Links.ps1',
    'External\Restore-Links.ps1',
    'External\Repair-BrokenLinks.ps1',
    'External\Remove-OrphanedLinks.ps1'
  )

  # Internal data to pass to the module specified in RootModule/ModuleToProcess
  InternalData       = @{
    PSData = @{
      Tags         = @('Links', 'SymbolicLink', 'HardLink', 'FileSystem')
      ProjectUri   = ''
      LicenseUri   = ''
      ReleaseNotes = 'Initial release of Links module'
    }
  }
}
