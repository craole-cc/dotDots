wt --window _quake "C:\\Program Files\\Git\\bin\\bash.exe"
@REM wt --window _quake "C:\\Program Files\\Git\\bin\\bash.exe" ; new-tab --profile "PowerShell" ; new-tab --profile "Nushell"

@REM wt --window _quake "C:\\Program Files\\Git\\bin\\bash.exe"; wt --window _quake "C:\\Program Files\\PowerShell\\7-preview\\pwsh.exe"; new-tab "C:\\Users\\mrcra\\AppData\\Local\\Programs\\nu\\bin\\nu.exe"


@REM wt --window _quake "C:\\Program Files\\Git\\bin\\bash.exe" -NoLogo -WindowStyle Minimized; new-tab "C:\\Program Files\\Git\\bin\\bash.exe"

@REM ---------------------------
@REM Help
@REM ---------------------------
@REM wt - the Windows Terminal
@REM Usage: [OPTIONS] [SUBCOMMAND]

@REM Options:
@REM   -h,--help                   Print this help message and exit
@REM   -v,--version                Display the application version
@REM   -M,--maximized Excludes: --fullscreen
@REM                               Launch the window maximized
@REM   -F,--fullscreen Excludes: --focus --maximized
@REM                               Launch the window in fullscreen mode
@REM   -f,--focus Excludes: --fullscreen
@REM                               Launch the window in focus mode
@REM   --pos TEXT                  Specify the position for the terminal, in "x,y" format.
@REM   --size TEXT                 Specify the number of columns and rows for the terminal, in "c,r" format.
@REM   -w,--window TEXT            Specify a terminal window to run the given commandline in. "0" always refers to the current window.
@REM   -s,--saved INT              This parameter is an internal implementation detail and should not be used.

@REM Subcommands:
@REM   new-tab                     Create a new tab
@REM   nt                          An alias for the "new-tab" subcommand.
@REM   split-pane                  Create a new split pane
@REM   sp                          An alias for the "split-pane" subcommand.
@REM   focus-tab                   Move focus to another tab
@REM   ft                          An alias for the "focus-tab" subcommand.
@REM   move-focus                  Move focus to the adjacent pane in the specified direction
@REM   mf                          An alias for the "move-focus" subcommand.
@REM   move-pane                   Move focused pane to another tab
@REM   mp                          An alias for the "move-pane" subcommand.
@REM   swap-pane                   Swap the focused pane with the adjacent pane in the specified direction
@REM   focus-pane                  Move focus to another pane
@REM   fp                          An alias for the "focus-pane" subcommand.

@REM ---------------------------
@REM OK
@REM ---------------------------
