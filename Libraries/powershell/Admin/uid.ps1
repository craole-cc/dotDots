#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Creates a sortable, process-aware identifier.

.DESCRIPTION
    Writes an identifier in the form:

        yyyyMMddHHmmss_PID_PPID_random

    The timestamp keeps identifiers lexically sortable. PID and parent PID add
    process context, while four cryptographically random bytes reduce collisions
    between identifiers produced in the same second.

.OUTPUTS
    [string]
    A timestamp, zero-padded process IDs, and an eight-character lowercase
    hexadecimal suffix separated by underscores.

.EXAMPLE
    ./uid.ps1

    20260918150000_01234_00001_a1b2c3d4

.NOTES
    This is an identifier generator, not a UUID implementation.
#>
[CmdletBinding()]
param()

$timestamp = Get-Date -Format 'yyyyMMddHHmmss'
$parentProcessId = try {
  (Get-Process -Id $PID -ErrorAction Stop).Parent.Id
}
catch {
  0
}

$randomBytes = New-Object byte[] 4
$randomGenerator = [Security.Cryptography.RandomNumberGenerator]::Create()
try {
  $randomGenerator.GetBytes($randomBytes)
}
finally {
  $randomGenerator.Dispose()
}

$randomSuffix = -join ($randomBytes | ForEach-Object { $_.ToString('x2') })

'{0}_{1:d5}_{2:d5}_{3}' -f $timestamp, $PID, $parentProcessId, $randomSuffix
