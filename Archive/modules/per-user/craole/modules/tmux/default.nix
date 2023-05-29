{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.zfs-root.per-user.craole.modules.tmux;
  inherit (lib) mkDefault mkOption types mkIf;
in {
  options.zfs-root.per-user.craole.modules.tmux.enable = mkOption {
    type = types.bool;
    default = config.zfs-root.per-user.craole.enable;
  };
  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      keyMode = "emacs";
      newSession = true;
      secureSocket = true;
      terminal = "tmux-direct";
      historyLimit = 4096;
      baseIndex = 1;
      extraConfig = ''
        unbind C-b
        unbind f7

        set -u prefix
        set -g prefix f7
        bind -N "Send the prefix key through to the application" \
          f7 send-prefix

        bind-key -T prefix t new-session
        # toggle status bar with f7+f8
        set -g status off
        bind-key -T prefix f8 set-option -g status

        # disable cpu intensive auto-rename
        setw -g automatic-rename off

        # transparent status bar
        set-option -g status-style bg=default
      '';
    };
  };
}
