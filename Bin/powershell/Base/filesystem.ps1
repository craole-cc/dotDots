<#
.SYNOPSIS
    PowerShell Filesystem Utilities Module
.DESCRIPTION
    Provides POSIX-style path handling and filesystem utilities for cross-platform compatibility.
.AUTHOR
    Craig 'Craole' Cole
.COPYRIGHT
    (c) Craig 'Craole' Cole, 2025. All rights reserved.
.LICENSE
    MIT License
.NOTES
    This module is designed for modular dotfile and script management.
#>

#region Configuration

#~@ Default path separators
$script:PathSeparators = @{
    Windows = '\'
    POSIX   = '/'
}

#~@ Path normalization patterns
$script:PathPatterns = @{
    UNCPrefix     = '^//'
    MultipleSlash = '/+'
    BackToForward = '\\'
}

#endregion
#region Methods

function Format-PathPOSIX {
    <#
    .SYNOPSIS
        Normalizes a path by converting it to POSIX format with forward slashes.
    .PARAMETER Path
        The path to normalize.
    .OUTPUTS
        [string] The normalized POSIX-style path.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [string]$Path
    )

    process {
        try {
            #~@ Get full path and normalize slashes
            $fullPath = [System.IO.Path]::GetFullPath($Path)
            $posixPath = $fullPath.Replace(
                $script:PathSeparators.Windows,
                $script:PathSeparators.POSIX
            )

            #~@ Handle UNC paths specially
            if ($posixPath -match $script:PathPatterns.UNCPrefix) {
                return $posixPath -replace $script:PathPatterns.MultipleSlash, $script:PathSeparators.POSIX
            }

            #~@ Return normalized path
            return $posixPath
        }
        catch {
            Write-Error "Failed to normalize path: $_"
            return $null
        }
    }
}

function Resolve-PathPOSIX {
    <#
    .SYNOPSIS
        Resolves and normalizes paths to absolute POSIX format.
    .PARAMETER Path
        The path(s) to resolve and convert.
    .OUTPUTS
        [string] The resolved POSIX-style path.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Path
    )

    process {
        try {
            $resolved = Resolve-Path -Path $Path -ErrorAction Stop
            foreach ($item in $resolved) {
                $posixPath = $item.Path -replace $script:PathPatterns.BackToForward, $script:PathSeparators.POSIX

                if ($posixPath -match $script:PathPatterns.UNCPrefix) {
                    #~@ Preserve UNC prefix
                    $posixPath = ($posixPath.Substring(0, 2)) +
                                ($posixPath.Substring(2) -replace $script:PathPatterns.MultipleSlash, $script:PathSeparators.POSIX)
                }
                else {
                    #~@ Normalize other paths
                    $posixPath = $posixPath -replace "([^:]/)/+", '$1'
                }

                return $posixPath
            }
        }
        catch {
            Write-Error $_
            return $null
        }
    }
}

#endregion
#region Export

Export-ModuleMember -Function @(
    'Format-PathPOSIX',
    'Resolve-PathPOSIX'
)

Set-Alias -Name posix -Value Format-PathPOSIX
Set-Alias -Name resolve-posix -Value Resolve-PathPOSIX

#endregion
