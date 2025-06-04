$src = "$env:APPDATA\johnsadventures.com\Background Switcher\LockScreen"
$dest = if ($env:WALLPAPER -and $env:WALLPAPER.Trim()) { $env:WALLPAPER } else { Join-Path $env:USERPROFILE 'Pictures\Wallpaper.jpg' }
$latest = Get-ChildItem $src | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Copy-Item $latest.FullName $dest -Force
