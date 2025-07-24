function Global:Get-OrdinalString {
  <#
      .SYNOPSIS
      Returns the ordinal string (e.g., "1st", "2nd", "3rd", "4th", etc.) for a given integer.

      .PARAMETER Number
      The integer to convert to an ordinal string.

      .OUTPUTS
      [string] The ordinal string representation.

      .EXAMPLE
      Get-OrdinalString 1
      # Returns "1st"

      .EXAMPLE
      Get-OrdinalString 22
      # Returns "22nd"
    #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 0)]
    [int]$Number
  )

  #{ Handle negative or zero input gracefully
  if ($Number -le 0) {
    return "$Number"
  }

  $lastTwo = $Number % 100
  $lastOne = $Number % 10

  if ($lastTwo -ge 11 -and $lastTwo -le 13) {
    return "${Number}th"
  }

  switch ($lastOne) {
    1 { return "${Number}st" }
    2 { return "${Number}nd" }
    3 { return "${Number}rd" }
    default { return "${Number}th" }
  }
}

