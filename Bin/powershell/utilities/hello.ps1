function Global:Greetings {
    <#
    .SYNOPSIS
    Outputs a friendly greeting message.

    .DESCRIPTION
    The Greetings function prints a greeting message to the host console. It accepts a Name and an optional Greeting string.
    If the Greeting parameter is omitted, the function uses the invocation name (function name or alias used) as the greeting.
    Both the greeting and name are converted to Title Case for proper formatting.

    .PARAMETER Name
    The name of the person (or entity) to greet. Defaults to 'World' if not specified.

    .PARAMETER Greeting
    The greeting string to use (e.g., Hello, Hi, Howdy). If not provided, the function will use the alias or function name used to invoke the cmdlet.

    .EXAMPLE
    Greetings
    # Output: Hello World!  (if invoked via 'Greetings')

    .EXAMPLE
    hi Alice
    # Output: Hi Alice!  (assuming 'hi' is an alias for Greetings)

    .EXAMPLE
    hail Bob
    # Output: Hail Bob!  (assuming 'hail' alias)

    .EXAMPLE
    Greetings -Name "Sam" -Greeting "Hey"
    # Output: Hey Sam!

    .NOTES
    Define aliases pointing to this function to customize greeting words conveniently.
    Uses $MyInvocation.InvocationName to detect how the function was called.

    #>

    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            HelpMessage = "Specify the name of the person to greet. Defaults to 'World'."
        )]
        [string]$Name = 'World',

        [Alias('Greet')]
        [Parameter(
            Position = 1,
            HelpMessage = "Specify the greeting to use (e.g., Hello, Hi). If omitted, the invocation name is used."
        )]
        [string]$Greeting
    )

    # If the Greeting parameter was NOT explicitly passed, use the invocation name or alias as the greeting
    if (-not $PSBoundParameters.ContainsKey('Greeting')) {
        $Greeting = $MyInvocation.InvocationName
    }

    # Convert both Greeting and Name to Title Case for neat output
    $cultureInfo = [System.Globalization.CultureInfo]::CurrentCulture
    $textInfo = $cultureInfo.TextInfo

    $greetingCase = $textInfo.ToTitleCase($Greeting)
    $nameCase = $textInfo.ToTitleCase($Name)

    # Output the greeting
    Write-Host "$greetingCase $nameCase!"
}

Set-Alias -Name hi -Value Greetings -Scope Global
Set-Alias -Name hey -Value Greetings -Scope Global
Set-Alias -Name hail -Value Greetings -Scope Global
Set-Alias -Name hello -Value Greetings -Scope Global
Set-Alias -Name howdy -Value Greetings -Scope Global
