function Remove-Folder {
  <#
    .SYNOPSIS
        Removes a directory.
    .DESCRIPTION
        Prompts the user cor confirmation before removing the directory.
    .PARAMETER Path
        The path to delete. Defaults to current location.
    .OUTPUTS
        [string] Path to the backup directory
    .EXAMPLE
        Remove-Folder
        - Creates a backup of the current directory in the parent directory.
        - Changes to the parent directory
        - Deletes the target directory
    .EXAMPLE
        Remove-Folder -Path "C:\MyProject"
        Creates a backup of C:\MyProject in C:\archive with format: MyProject-20241104_143022
    #>
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline = $true)]
    [Alias ('Folder', 'Directory' , 'Dir')]
    [string]$Path = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [Alias ('Dry', 'Dry-Run' , 'Simulate')]
    [switch]$WhatIf
  )

  $target = Resolve-Path $Path
  $parent = Split-Path $target -Parent

  if ($WhatIf) {
    Backup-Folder -Path $target -WhatIf
  }
  else {
    try { Backup-Folder -Path $target }
    catch {
      Write-Pretty -NoNewLine -Tag 'Error' "Backup failed: $($_.Exception.Message)"
      return $null
    }
  }

  if ($Path -eq (Get-Location).Path) {
    if ($WhatIf) {
      Write-Pretty -NoNewLine -Tag 'Warn' "Would change directory to '$parent'"
    }
    else {
      try { Set-Location $parent }
      catch {
        Write-Pretty -NoNewLine -Tag 'Error' "Failed to chage directory: $($_.Exception.Message)"
        return $null
      }
    }
  }

  if ($WhatIf) {
    Write-Pretty -NoNewLine -Tag 'Warn' "Would delete '$target'"
  }
  else {
    try { Remove-Item -Path $target -Recurse -Force }
    catch {
      Write-Pretty -NoNewLine -Tag 'Error' "Failed to remove dirctory: $($_.Exception.Message)"
      return $null
    }
  }
}
