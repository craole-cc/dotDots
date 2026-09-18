#!/usr/bin/env nu
let time = (date now | format date "%Y%m%d%H%M%S");
let ppid = (try { ps | where pid == $nu.pid | get ppid.0 } catch { 0 });
let pid_fmt = ($nu.pid | into string | fill -a right -c '0' -w 5);
let ppid_fmt = ($ppid | into string | fill -a right -c '0' -w 5);
let rand_hex = (random binary 4 | encode hex --lower);
$"($time)_($pid_fmt)_($ppid_fmt)_($rand_hex)"
