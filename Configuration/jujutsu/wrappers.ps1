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

function Global:Invoke-JujutsuCleanup {
  <#
    .SYNOPSIS
        Cleans up commits without descriptions in the current branch.
    .PARAMETER Branch
        The branch/bookmark to clean (default: main).
    .PARAMETER Message
        If provided, describes commits with this message instead of squashing.
    .PARAMETER NoSquash
        Prompt for descriptions instead of squashing.
    #>
  [CmdletBinding()]
  param(
    [string]$Branch = 'main',
    [string]$Message,
    [switch]$NoSquash
  )

  Write-Pretty -Tag 'Info' "Checking for undescribed commits in $Branch..."

  # Find all commits without descriptions that are NOT immutable
  $query = "ancestors($Branch) & description(exact:"""") & ~immutable() & ~root()"
  $undescribed = jj log -r $query --no-graph --color never -T 'change_id ++ " " ++ commit_id.short()' |
    Where-Object { $_ }

  if (-not $undescribed) {
    Write-Pretty -Tag 'Success' 'No undescribed mutable commits found!'
    return
  }

  $count = ($undescribed | Measure-Object).Count
  Write-Pretty -Tag 'Warning' "Found $count undescribed commit(s)"

  if ($Message) {
    # Describe all with provided message
    Write-Pretty -Tag 'Info' "Describing commits with message: '$Message'"
    foreach ($line in $undescribed) {
      $changeId = $line.Split()[0].Trim()
      jj describe $changeId --message $Message 2>&1 | Out-Null
    }
  } elseif ($NoSquash) {
    # Prompt for descriptions
    foreach ($line in $undescribed) {
      $parts = $line.Split()
      $changeId = $parts[0].Trim()
      $commitShort = $parts[1].Trim()

      Write-Host "`nCommit: " -NoNewline -ForegroundColor Cyan
      Write-Host $commitShort -ForegroundColor Yellow
      jj log -r $changeId --no-graph

      $userMessage = Read-Host "`nEnter description (or press Enter to skip)"

      if ($userMessage) {
        jj describe $changeId --message $userMessage
      } else {
        Write-Pretty -Tag 'Warning' "Skipped: $commitShort"
      }
    }
  } else {
    # Default: Squash empty commits
    Write-Pretty -Tag 'Info' 'Squashing undescribed commits...'
    foreach ($line in $undescribed) {
      $changeId = $line.Split()[0].Trim()
      Write-Pretty -Tag 'Debug' "Squashing: $changeId"
      jj squash --revision $changeId 2>&1 | Out-Null
    }
  }

  Write-Pretty -Tag 'Success' 'Cleanup complete!'
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
    .PARAMETER SkipCleanup
        Skip automatic cleanup of undescribed commits.
    #>
  [CmdletBinding()]
  param(
    [Parameter(Position = 0)]
    [string]$Message,

    [string]$Branch = 'main',

    [Alias('b', 'back')]
    [switch]$AllowBackwards,

    [Alias('f')]
    [switch]$Force,

    [switch]$SkipCleanup
  )

  Write-Pretty -NoNewLine -Tag 'Debug' 'Removing JJ lock if present...'
  Remove-Item -Path .jj/working_copy/working_copy.lock -ErrorAction SilentlyContinue

  # Auto-cleanup undescribed commits unless skipped
  if (-not $SkipCleanup) {
    Write-Pretty -Tag 'Debug' 'Running automatic cleanup...'
    Invoke-JujutsuCleanup -Branch $Branch
  }

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

  # Push the bookmark
  Write-Pretty -Tag 'Debug' 'Pushing to remote...'
  if ($Force) {
    jj git push --bookmark $Branch --force
  } else {
    jj git push --bookmark $Branch
  }

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
Set-Alias -Name jj-prep -Value Invoke-JujutsuCleanup -Scope Global -Force
Set-Alias -Name jj-push -Value Invoke-JujutsuPush -Scope Global -Force
Set-Alias -Name jj-reup -Value Invoke-JujutsuReup -Scope Global -Force
