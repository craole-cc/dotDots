@echo off
@REM set SRC=C:\Users\Administrator\AppData\Roaming\johnsadventures.com\Background Switcher\LockScreen
set SRC="%AppData%\Roaming\johnsadventures.com\Background Switcher\LockScreen"
set DEST="%USERPROFILE%\Pictures\Wallpaper.jpg"

rem Find the most recently modified file in the LockScreen folder
for /f "delims=" %%a in ('dir "%SRC%\*" /b /a-d /o-d') do (
    copy "%SRC%\%%a" "%DEST%" /Y
    goto :done
)
:done
