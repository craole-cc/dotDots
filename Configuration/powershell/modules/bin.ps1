# function Global:InitBin {
#   [CmdletBinding()]
#   param()

  if ($env:DOTS) {
    $path = Join-Path -Path $env:DOTS -ChildPath 'Bin'
    $path = & NormalizePath $path



    #@ Set profile path in all scopes
    [Environment]::SetEnvironmentVariable('DOTS_BIN', $path, 'Process')
    $Global:DOTS_BIN = $path
    Set-Item -Path 'env:DOTS_BIN' -Value $path
    # Pout -lvl "Info" -msg "DOTS_BIN environment set to: $Global:DOTS_BIN"

        Pout -Level Info `
        -Message "DOTS_BIN environment set to: $path"
      }
      # }

      # -Context $MyInvocation `
# RunCommand InitBin
