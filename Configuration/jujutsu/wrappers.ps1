<#
.SYNOPSIS
    Jujutsu (jj) workflow wrapper functions.

.DESCRIPTION
    Provides PowerShell wrapper functions for common jj workflows including
    pull, push, and reup operations. Requires Admin/backup.ps1 to be loaded.

.NOTES
    Author: Craig
    Place in Configuration/jujutsu/wrappers.ps1
#>

function Global:Invoke-JujutsuPull {
  <#
    .SYNOPSIS
        Pulls changes from remote using jj.
    .DESCRIPTION
        Fetches from remote origin and rebases jj state, then syncs with git.
    .PARAMETER Branch
        The branch to rebase onto (default: main@origin).
    #>
  [CmdletBinding()]
  param(
    [string]$Branch = 'main@origin'
  )

  Write-Pretty -NoNewLine -Tag 'Debug' 'Fetching and rebasing with jj...'
  jj git fetch --remote origin
  jj rebase --destination $Branch

  Write-Pretty -NoNewLine -Tag 'Info' 'Pull complete!'
}

function Global:Invoke-JujutsuPush {
  <#
    .SYNOPSIS
        Pushes changes to remote with jj.
    .PARAMETER Branch
        The bookmark/branch name to set and push (default: main).
    .PARAMETER AllowBackwards
        Allow backwards bookmark movement.
    .PARAMETER Force
        Force push even if remote changed.
    .PARAMETER Message
        Commit message for the push.
    #>
  [CmdletBinding()]
  param(
    [Parameter(Position = 0)]
    [string]$Message,

    [string]$Branch = 'main',

    [Alias('b', 'back')]
    [switch]$AllowBackwards,

    [Alias('f')]
    [switch]$Force
  )

  Write-Pretty -NoNewLine -Tag 'Debug' 'Removing JJ lock if present...'
  Remove-Item -Path .jj/working_copy/working_copy.lock -ErrorAction SilentlyContinue

  # Check if working copy has changes
  Write-Pretty -Tag 'Debug' 'Checking working copy status...'
  $emptyOutput = (jj log -r '@' --no-graph --color never -T 'empty' | Out-String).Trim()
  $isEmpty = $emptyOutput -eq 'true'

  if ($isEmpty) {
    # Already in a "new" - describe and push the parent
    Write-Pretty -Tag 'Debug' 'Working copy is empty, describing parent...'
    if ($Message) {
      jj describe '@-' --message $Message
    } else {
      jj describe '@-'
    }
  } else {
    # Working copy has changes - describe current, then make new
    Write-Pretty -Tag 'Debug' 'Describing current working copy...'
    if ($Message) {
      jj describe --message $Message
    } else {
      jj describe
    }

    Write-Pretty -Tag 'Debug' 'Creating new working copy...'
    jj new
  }

  # Set bookmark to @- (the commit we want to push)
  Write-Pretty -Tag 'Debug' "Setting bookmark '$Branch' to @-..."
  if ($AllowBackwards) {
    jj bookmark set $Branch --revision '@-' --allow-backwards
  } else {
    jj bookmark set $Branch --revision '@-'
  }

  # Push the bookmark (allow empty and new commits)
  Write-Pretty -Tag 'Debug' 'Pushing to remote...'
  $pushArgs = @('git', 'push', '--bookmark', $Branch)
  if ($Force) {
    $pushArgs += '--force'
  }
  & jj $pushArgs

  Write-Pretty -Tag 'Info' 'Push complete!'
}

function Global:Invoke-JujutsuReup {
  <#
    .SYNOPSIS
        Pull, backup, and push with allow-backwards in one operation.
    .DESCRIPTION
        Comprehensive workflow: pulls changes, creates backup, pushes with allow-backwards.
        Requires New-BackupCopy function from Admin/backup.ps1.
    .PARAMETER Force
        Force push even if remote changed.
    #>
  [CmdletBinding()]
  param(
    [switch]$Force
  )

  Invoke-JujutsuPull
  $backupPath = New-BackupCopy

  if ($backupPath) {
    Invoke-JujutsuPush -AllowBackwards -Force:$Force
    Write-Pretty -NoNewLine -Tag 'Success' "jjReup complete! Don't forget to delete the backup folder if everything looks good:"
    Write-Pretty -NoNewLine -Tag 'Debug' "  $backupPath"
  }
  else {
    Write-Pretty -NoNewLine -Tag 'Error' 'Backup failed, aborting push operation.'
  }
}

# -- Aliases
Set-Alias -Name jj-pull -Value Invoke-JujutsuPull -Scope Global -Force
Set-Alias -Name jj-push -Value Invoke-JujutsuPush -Scope Global -Force
Set-Alias -Name jj-reup -Value Invoke-JujutsuReup -Scope Global -Force
