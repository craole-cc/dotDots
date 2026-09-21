<#
.SYNOPSIS
Formats PowerShell source using PSScriptAnalyzer.

.DESCRIPTION
Formats PowerShell source using PSScriptAnalyzer's Invoke-Formatter.

The script supports two modes:

- File mode formats one or more PowerShell files in-place.
- Stdin mode reads PowerShell source from standard input and writes the
  formatted source to standard output.

Formatting indentation is read from the nearest applicable .editorconfig.
The following EditorConfig properties are supported:

    indent_style = space | tab
    indent_size  = <number> | tab

PSScriptAnalyzer is provided by the surrounding environment. This script
does not install or modify PowerShell modules.

.PARAMETER stdin
Reads PowerShell source from standard input and writes the formatted source
to standard output.

.PARAMETER FilePaths
One or more PowerShell script paths to format in-place.

.EXAMPLE
pwshfmt script.ps1

Formats script.ps1 in-place.

.EXAMPLE
pwshfmt script1.ps1 script2.ps1

Formats multiple PowerShell files in-place.

.EXAMPLE
Get-Content script.ps1 -Raw | pwshfmt --stdin

Formats PowerShell source received through standard input.

.NOTES
Formatting indentation is controlled by .editorconfig.

For example:

    [*.ps1]
    indent_style = space
    indent_size = 2

If no applicable .editorconfig is found, PSScriptAnalyzer's defaults are
used.

PSScriptAnalyzer is supplied externally and is not installed by this script.
#>

[CmdletBinding()]
param(
  [switch]$stdin,

  [Parameter(Position = 0, ValueFromRemainingArguments)]
  [string[]]$FilePaths
)

$ErrorActionPreference = "Stop"

Import-Module PSScriptAnalyzer


function Get-EditorConfigPath {
  param(
    [Parameter(Mandatory)]
    [string]$Path
  )

  $directory = if (Test-Path -LiteralPath $Path -PathType Container) {
    (Resolve-Path -LiteralPath $Path).ProviderPath
  }
  else {
    (Resolve-Path -LiteralPath (Split-Path -Parent $Path)).ProviderPath
  }

  while ($true) {
    $config = Join-Path $directory ".editorconfig"

    if (Test-Path -LiteralPath $config -PathType Leaf) {
      return $config
    }

    $parent = [System.IO.Directory]::GetParent($directory)

    if ($null -eq $parent) {
      return $null
    }

    $directory = $parent.FullName
  }
}


function Get-EditorConfigIndentation {
  param(
    [Parameter(Mandatory)]
    [string]$FilePath
  )

  $configPath = Get-EditorConfigPath $FilePath

  if ($null -eq $configPath) {
    return @{}
  }

  $extension = [System.IO.Path]::GetExtension($FilePath).ToLowerInvariant()

  $sections = @{}
  $currentSection = $null

  foreach ($line in [System.IO.File]::ReadLines($configPath)) {
    $line = $line.Trim()

    if (
      [string]::IsNullOrWhiteSpace($line) -or
      $line.StartsWith("#") -or
      $line.StartsWith(";")
    ) {
      continue
    }

    if ($line -match '^\[(.+)\]$') {
      $currentSection = $Matches[1]
      $sections[$currentSection] = @{}
      continue
    }

    if (
      $null -ne $currentSection -and
      $line -match '^\s*([^=]+?)\s*=\s*(.*?)\s*$'
    ) {
      $key = $Matches[1].Trim().ToLowerInvariant()
      $value = $Matches[2].Trim()

      $sections[$currentSection][$key] = $value
    }
  }

  $settings = @{}

  foreach ($section in $sections.Keys) {
    $matches = $false

    switch ($section) {
      "*" {
        $matches = $true
      }

      "*.ps1" {
        $matches = $extension -eq ".ps1"
      }

      "*.psm1" {
        $matches = $extension -eq ".psm1"
      }

      "*.psd1" {
        $matches = $extension -eq ".psd1"
      }
    }

    if ($matches) {
      foreach ($key in $sections[$section].Keys) {
        $settings[$key] = $sections[$section][$key]
      }
    }
  }

  return $settings
}


function New-FormatterSettings {
  param(
    [Parameter(Mandatory)]
    [string]$FilePath
  )

  $editorConfig = Get-EditorConfigIndentation $FilePath

  $rules = @{}

  if ($editorConfig.ContainsKey("indent_style")) {
    $style = $editorConfig["indent_style"]

    switch ($style) {
      "space" {
        $kind = "space"
      }

      "tab" {
        $kind = "tab"
      }

      default {
        $kind = $null
      }
    }

    if ($null -ne $kind) {
      $indentation = @{
        Enable              = $true
        Kind                = $kind
        PipelineIndentation = "IncreaseIndentationForFirstPipeline"
      }

      if ($editorConfig.ContainsKey("indent_size")) {
        $size = $editorConfig["indent_size"]

        if ($size -match '^\d+$') {
          $indentation.IndentationSize = [int]$size
        }
      }

      $rules.PSUseConsistentIndentation = $indentation
    }
  }

  $rules.PSTrimWhitespaceAroundPipe = @{
    Enable = $true
  }

  $rules.PSWhitespaceBetweenParameters = @{
    Enable = $true
  }

  return @{
    Rules = $rules
  }
}


function Format-Code {
  param(
    [Parameter(Mandatory)]
    [string]$Code,

    [Parameter(Mandatory)]
    [string]$FilePath
  )

  $settings = New-FormatterSettings $FilePath

  Invoke-Formatter `
    -ScriptDefinition $Code `
    -Settings $settings
}


if ($stdin) {
  $reader = [System.IO.StreamReader]::new(
    [System.Console]::OpenStandardInput()
  )

  try {
    $source = $reader.ReadToEnd()
  }
  finally {
    $reader.Dispose()
  }

  # stdin has no inherent file path, so use the current directory
  # when resolving .editorconfig.
  $virtualPath = Join-Path (Get-Location) "stdin.ps1"

  Format-Code $source $virtualPath
  exit 0
}


if ($FilePaths.Count -eq 0) {
  exit 0
}


$utf8NoBom = [System.Text.UTF8Encoding]::new($false)


foreach ($file in $FilePaths) {
  if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
    [Console]::Error.WriteLine(
      "pwshfmt: file not found: $file"
    )
    exit 1
  }

  $path = (Resolve-Path -LiteralPath $file).ProviderPath
  $source = [System.IO.File]::ReadAllText($path)

  $formatted = Format-Code $source $path

  if ($formatted -ne $source) {
    [System.IO.File]::WriteAllText(
      $path,
      $formatted,
      $utf8NoBom
    )
  }
}
