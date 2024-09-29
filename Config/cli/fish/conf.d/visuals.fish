#===============================================================
#
# ALIASES
# ~/.config/fish/conf.d/alias.fish
#
#===============================================================

### RANDOM COLOR SCRIPT ###
# Get this script from my GitLab: gitlab.com/dwt1/shell-color-scripts
# Or install it from the Arch User Repository: shell-color-scripts
# colorscript random

### SYSTEM INFO ###
# paleofetch
# neofetch
# pfetch
# fastfetch
# freshfetch

### TERMINAL TYPE ###
set TERM "xterm-256color"

### SETTING THE STARSHIP PROMPT ###
starship init fish | source

# === Icons-In-Terminal === #
source /usr/share/icons-in-terminal/icons.fish

### COLOR SCHEME ###
# set theme_color_scheme base16-dark
# set theme_color_scheme dracula
set theme_color_scheme gruvbox
# set theme_color_scheme solarized-dark
# set theme_color_scheme nord
# set theme_color_scheme zenburn
# set theme_color_scheme terminal
# set theme_color_scheme terminal2

### AUTOCOMPLETE AND HIGHLIGHT COLORS ###
set fish_color_normal brcyan
set fish_color_autosuggestion '#7d7d7d'
set fish_color_command brcyan
set fish_color_error '#ff6c6b'
set fish_color_param brcyan

### THEME OVERRIDES ###
# set -g theme_display_git no
# set -g theme_display_git_dirty no
# set -g theme_display_git_untracked no
# set -g theme_display_git_ahead_verbose yes
# set -g theme_display_git_dirty_verbose yes
# set -g theme_display_git_stashed_verbose yes
# set -g theme_display_git_default_branch yes
# set -g theme_git_default_branches master main
# set -g theme_git_worktree_support yes
# set -g theme_use_abbreviated_branch_name yes
# set -g theme_display_vagrant yes
# set -g theme_display_docker_machine no
# set -g theme_display_k8s_context yes
# set -g theme_display_hg yes
# set -g theme_display_virtualenv no
# set -g theme_display_nix no
# set -g theme_display_ruby no
set -g theme_display_node yes
set -g theme_display_user ssh
set -g theme_display_hostname ssh
set -g theme_display_vi no
# set -g theme_display_date no
set -g theme_display_cmd_duration yes
set -g theme_title_display_process yes
set -g theme_title_display_path no
# set -g theme_title_display_user yes
# set -g theme_title_use_abbreviated_path no
set -g theme_date_format "+%a %H:%M"
set -g theme_date_timezone America/New_York
# set -g theme_avoid_ambiguous_glyphs yes
# set -g theme_powerline_fonts no
set -g theme_nerd_fonts yes
# set -g theme_show_exit_status yes
# set -g theme_display_jobs_verbose yes
# set -g default_user your_normal_user
# set -g fish_prompt_pwd_dir_length 0
# set -g theme_project_dir_length 1
# set -g theme_newline_cursor yes
# set -g theme_newline_prompt '$ '