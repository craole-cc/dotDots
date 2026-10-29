{
  config,
  lix,
  name,
  pkgs,
  editor ? "helix",
  command ? lix.sources.access.getExe config.programs.helix.package,
  ...
}: let
  inherit (lix.strings.transformation) escapeShellArg;
  socket = "dotdots-${editor}";
  tmuxConfig = pkgs.writeText "${name}-tmux.conf" ''
    # Keep the editor alive after its terminal client closes.
    set -g destroy-unattached off
    set -g status off
    set -g prefix None
    unbind-key C-b
    set -g default-terminal "tmux-256color"
    set -as terminal-features ",*:RGB"
    set -s escape-time 0
  '';
  tracker = pkgs.writeShellApplication {
    name = "${name}-track-project";
    runtimeInputs = [pkgs.coreutils pkgs.tmux pkgs.util-linux];
    text = ''
      state_directory=$1
      umask 077
      exec 9>"$state_directory/tracker.lock"
      flock -n 9 || exit 0
      while project=$(tmux -L ${escapeShellArg socket} display-message -p -t ${escapeShellArg "${editor}:0.0"} '#{pane_current_path}' 2>/dev/null); do
        if [ -d "$project" ]; then
          printf '%s\n' "$project" > "$state_directory/project.tmp"
          mv -f "$state_directory/project.tmp" "$state_directory/project"
        fi
        sleep 2
      done
    '';
  };
in
  pkgs.writeShellApplication {
    inherit name;
    runtimeInputs = [pkgs.coreutils pkgs.tmux];
    text = ''
      unset TMUX
      umask 077
      state_directory="''${XDG_STATE_HOME:-$HOME/.local/state}/dotdots/editors/${editor}"
      mkdir -p "$state_directory"

      if [ "$#" -eq 0 ]; then
        if [ -r "$state_directory/project" ]; then
          IFS= read -r project < "$state_directory/project" || true
          if [ -n "''${project:-}" ] && [ -d "$project" ]; then
            cd -- "$project"
          fi
        fi
        set -- .
      fi

      # Keep the editor alive when its terminal closes, and save its current
      # project independently so the next login can reopen that directory.
      if ! tmux -L ${escapeShellArg socket} has-session -t ${escapeShellArg editor} 2>/dev/null; then
        tmux -L ${escapeShellArg socket} -f ${tmuxConfig} \
          new-session -d -s ${escapeShellArg editor} -n ${escapeShellArg editor} -c "$PWD" -- \
          ${escapeShellArg command} "$@"
      fi
      nohup ${tracker}/bin/${tracker.name} "$state_directory" >/dev/null 2>&1 </dev/null &
      exec tmux -L ${escapeShellArg socket} attach-session -t ${escapeShellArg editor}
    '';
  }
