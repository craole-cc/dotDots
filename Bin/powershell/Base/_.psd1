@{
  # Script module or binary module file associated with this manifest.
  RootModule        = '_.psm1'

  # Version number of this module.
  ModuleVersion     = '1.0.0'

  # ID used to uniquely identify this module
  GUID              = '12345678-1234-1234-1234-123456789012'

  # Author of this module
  Author            = "Craig 'Craole' Cole"

  # Company or vendor of this module
  CompanyName       = 'Personal'

  # Copyright statement for this module
  Copyright         = '(c) Craig Cole 2025. All rights reserved.'

  # Description of the functionality provided by this module
  Description       = 'PowerShell utilities for verbosity-aware logging, context management, and cross-platform path handling.'

  # Minimum version of the PowerShell engine required by this module
  PowerShellVersion = '5.1'

  # Functions to export from this module
  FunctionsToExport = @(
    'Invoke-Process',
    'Test-InvokeProcess',
    'Get-Context',
    'Test-GetContext',
    'Format-PathPOSIX',
    'Resolve-PathPOSIX',
    'Get-VerbosityDefault',
    'Get-VerbosityLevel',
    'Get-VerbosityNumeric',
    'Get-VerbosityColor',
    'Get-VerbosityTag',
    'Get-Verbosity',
    'Set-Verbosity',
    'Test-Verbosity',
    'Get-VerbosityAllAliases',
    'Get-VerbosityAliasesFor',
    'Format-VerbosityMessage',
    'Write-VerbosityMessage',
    'Compare-VerbosityLevel',
    'Test-VerbosityLevelMeetsThreshold',
    'Write-Pretty',
    'Test-WritePretty'
  )

  # Cmdlets to export from this module
  CmdletsToExport   = @()

  # Variables to export from this module
  VariablesToExport = @()

  # Aliases to export from this module
  AliasesToExport   = @(
    'posix',
    'resolve-posix',
    'pout'
  )

  # Private data to pass to the module specified in RootModule/ModuleToProcess
  PrivateData       = @{
    PSData = @{
      # Tags applied to this module
      Tags         = @('Logging', 'Verbosity', 'Utilities', 'CrossPlatform')

      # License for this module
      LicenseUri   = ''

      # Project site for this module
      ProjectUri   = ''

      # Icon for this module
      IconUri      = ''

      # Release notes for this module
      ReleaseNotes = 'Initial release with verbosity management, context resolution, and path utilities.'
    }
  }
}
