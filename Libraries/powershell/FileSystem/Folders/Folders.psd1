@{
  # Module manifest for Links
  RootModule        = 'Folders.psm1'
  ModuleVersion     = '1.0.0'
  GUID              = '12345678-1234-1234-1234-123456789011'
  Author            = 'Craig ''Craole'' Cole'
  CompanyName       = 'Cole-Bassed Solutions'
  Copyright         = '(c) 2025. All rights reserved.'
  Description       = 'PowerShell module for managing symbolic and hard links'

  # Minimum version of the PowerShell engine required by this module
  PowerShellVersion = '5.0'

  # Functions to export from this module
  FunctionsToExport = @(
    'Backup-Folder'
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
    'External\Backup-Folder.ps1'
  )

  # Internal data to pass to the module specified in RootModule/ModuleToProcess
  InternalData      = @{
    PSData = @{
      Tags         = @('Folder', 'FileSystem')
      ProjectUri   = ''
      LicenseUri   = ''
      ReleaseNotes = 'Initial release of Folders module'
    }
  }
}
