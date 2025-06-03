
function Global:Write-Message {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [ValidateSet('Trace', 'Debug', 'Info', 'Warn', 'Error')]
        [string]$Level = 'Info',

        [switch]$Timestamp,

        [string]$Context
    )

    $levelMap = @{
        'Trace' = @{ Number = 5; Color = 'Magenta'; Tag = 'TRACE' }
        'Debug' = @{ Number = 4; Color = 'Yellow'; Tag = 'DEBUG' }
        'Info'  = @{ Number = 3; Color = 'Green'; Tag = 'INFO' }
        'Warn'  = @{ Number = 2; Color = 'Red'; Tag = 'WARN' }
        'Error' = @{ Number = 1; Color = 'Red'; Tag = 'ERROR' }
    }

    $currentLevel = $levelMap[$Level]

    #{ Return early if verbosity level is too low
    if ($Global:VerbosityLevel -lt $currentLevel.Number) {
        return
    }

    #{ Build the message components
    $components = @()

    if ($Timestamp) {
        $components += Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }

    $components += $currentLevel.Tag

    if (-not [string]::IsNullOrEmpty($Context)) {
        $components += "|> $Global:ScriptName | $Context <|"
    } else {
        $components += "|> $Global:ScriptName <|"
    }

    $components += $Message

    #{ Output the message
    $fullMessage = $components -join ' '
    Write-Host $fullMessage -ForegroundColor $currentLevel.Color
}
