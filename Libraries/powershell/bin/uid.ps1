#!/usr/bin/env pwsh

$time = Get-Date -Format "yyyyMMddHHmmss";
$ppid = try { (Get-Process -Id $PID).Parent.Id } catch { 0 };$proc = "{0:d5}_{1:d5}" -f [int]$PID, [int]$ppid;
$rand = "{0:x8}" -f [int64](Get-Random -Maximum ([uint32]::MaxValue));
"$time`_$proc`_$rand"
