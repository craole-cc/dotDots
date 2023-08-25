#! /bin/sh

#==================================================
#
# FTC
#
#==================================================

# _________________________________ DOCUMENTATION<|

#   >> To enable command-not-found hook for your shell
# 	>> add any of the following to your .bashrc or .zshrc file
# 	>> depending on the shell you use:
# 	>> for bash:
# 	source /usr/share/doc/find-the-command/ftc.bash
# 	>> for zsh:
# 	source /usr/share/doc/find-the-command/ftc.zsh
# 	>> You can also append 'su' option to use su instead of sudo
# 	>> for root access, 'noprompt' to disable installation
# 	>> prompt at all, or 'quiet' to decrease verbosity, e.g.:
# 	source /usr/share/doc/find-the-command/ftc.zsh noprompt quiet

# _________________________________________ LOCAL<|

DIR=/usr/share/doc/find-the-command
ftcBASH="$DIR/ftc.bash"
ftcZSH="$DIR/ftc.zsh"
# ______________________________________ EXTERNAL<|

# 	>> Update Pacman
# sudo pacman -Fy
# systemctl enable pacman-files.timer

# __________________________________________ EXEC<|

if [ -d "$DIR" ]; then
    [ "$Shell" = bash ] &&
        . "$ftcBASH"
    [ "$Shell" = zsh ] &&
        . "$ftcZSH"
fi
