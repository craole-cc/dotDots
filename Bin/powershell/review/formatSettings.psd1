@{
  IncludeRules = @(
    'PSPlaceOpenBrace',
    'PSUseConsistentIndentation',
    'PSUseConsistentWhitespace'
  )
  Rules        = @{
    PSPlaceOpenBrace           = @{
      Enable     = $true
      OnSameLine = $false
    }
    PSUseConsistentIndentation = @{
      Enable = $true
      # tab length cannot currently be configured here (limitation)
    }
    PSUseConsistentWhitespace  = @{
      Enable = $true
    }
  }
}
