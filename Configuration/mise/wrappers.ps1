function Global:Invoke-Mise {
  <#
    .SYNOPSIS
        Invokes the mise command with provided arguments.
    .PARAMETER Arguments
        Arguments to pass to the mise command.
    #>
  param (
    [Parameter(ValueFromRemainingArguments = $true, Position = 0)]
    [string[]]$Arguments = @()
  )
  & mise @Arguments
}

function Global:Push-Mise {
  <#
    .SYNOPSIS
        Pushes changes to the remote repository using mise.
    #>
  mise push
  $ctx = 'mise push'
  if ($LASTEXITCODE -eq 0) {
    Write-Pretty -Tag 'Info' -NoNewLine -As $ctx 'Successfully committed changes to the remote repository.'
  }
  else {
    Write-Pretty -Tag 'Error' -NoNewLine -As $ctx 'Failed to push changes to the remote repository.'
  }
}

function Global:Format-Mise {
  <#
    .SYNOPSIS
        Lints the mise configuration.
    #>
  mise lint
  $ctx = 'mise lint'
  if ($LASTEXITCODE -eq 0) {
    Write-Pretty -Tag 'Info' -NoNewLine -As $ctx 'Linting completed without any issues.'
  }
  else {
    Write-Pretty -Tag 'Error' -NoNewLine -As $ctx 'Issues encountered during linting.'
  }
}
