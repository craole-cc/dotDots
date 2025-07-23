<#
.SYNOPSIS
A simple test function to verify PowerShell help examples work.

.DESCRIPTION
This function does nothing but return a string. It's purely for testing
whether PowerShell's Get-Help command can properly display examples.

.PARAMETER Message
The message to return. Defaults to "Hello World".

.PARAMETER Count
How many times to repeat the message. Defaults to 1.

.EXAMPLE
Test-Help
Returns "Hello World"

.EXAMPLE
Test-Help -Message "Testing"
Returns "Testing"

.EXAMPLE
Test-Help -Message "Repeat" -Count 3
Returns "RepeatRepeatRepeat"

.EXAMPLE
Test-Help "Custom" 2
Returns "CustomCustom"

.NOTES
This is a simple test function to verify help examples display correctly.

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help
#>
function Global:Test-Help {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0)]
    [string]$Message = 'Hello World',

    [Parameter(Position = 1)]
    [int]$Count = 1
  )

  return $Message * $Count
}
