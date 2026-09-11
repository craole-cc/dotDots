{
  apps,
  lib,
  ...
}: let
  roles = {
    primary = "PRI";
    secondary = "SEC";
    tertiary = "TER";
  };

  mkRoleVariables = prefix: set:
    lib.foldlAttrs (
      acc: role: suffix: let
        entry = set.${role} or null;
      in
        acc
        // lib.optionalAttrs (builtins.isAttrs entry && (entry.command or null) != null) {
          "${prefix}_${suffix}" = lib.mkDefault entry.command;
          "${prefix}_${suffix}_NAME" = lib.mkDefault entry.name;
        }
    )
    {}
    roles;

  primaryVariables =
    lib.optionalAttrs (builtins.isAttrs (apps.terminal.primary or null)) {
      TERMINAL = lib.mkDefault apps.terminal.primary.command;
    }
    // lib.optionalAttrs (builtins.isAttrs (apps.browser.primary or null)) {
      BROWSER = lib.mkDefault apps.browser.primary.command;
    }
    // lib.optionalAttrs (builtins.isAttrs (apps.editor.tty.primary or null)) {
      EDITOR = lib.mkDefault apps.editor.tty.primary.command;
    }
    // lib.optionalAttrs (builtins.isAttrs (apps.editor.gui.primary or null)) {
      VISUAL = lib.mkDefault apps.editor.gui.primary.command;
    }
    // lib.optionalAttrs (builtins.isAttrs (apps.explorer.primary or null)) {
      FILE_MANAGER = lib.mkDefault apps.explorer.primary.command;
    };
in {
  imports = [
    # Browsers
    ../browser/chromium
    ../browser/zen

    # Editors
    ../editor/helix
    ../editor/nvim
    ../editor/vim
    ../editor/vscode
    ../editor/zeditor

    # Information utilities
    ../info/btop.nix
    ../info/clock.nix
    ../info/fetchers.nix

    # Media
    ../media/editing
    ../media/freetube
    ../media/mpv
    ../media/obs

    # Shells
    ../shells/core/bash
    ../shells/core/fish
    ../shells/core/nushell
    ../shells/core/zsh
    ../shells/prompt/starship.nix

    # Shell tools
    ../shells/tools/atuin.nix
    ../shells/tools/bat.nix
    ../shells/tools/direnv.nix
    ../shells/tools/grep.nix
    ../shells/tools/home-manager.nix
    ../shells/tools/nh.nix
    ../shells/tools/nix-index.nix
    ../shells/tools/topgrade.nix
    ../shells/tools/yazi.nix

    # Terminals
    ../terminal/core/foot
    ../terminal/core/ghostty
    ../terminal/core/kitty
    ../terminal/tools/tmux

    # Version control
    ../version-control/core/git.nix
    ../version-control/core/jujutsu.nix
    ../version-control/clients/github.nix
    ../version-control/clients/gitui.nix
    ../version-control/tools/delta.nix
  ];

  # One normalized application-role contract for the session. Leaf modules may
  # provide stronger package-specific values; these defaults fill every role
  # name consistently, including tertiary and file-manager roles.
  home.sessionVariables =
    primaryVariables
    // (mkRoleVariables "TERMINAL" apps.terminal)
    // (mkRoleVariables "BROWSER" apps.browser)
    // (mkRoleVariables "EDITOR" apps.editor.tty)
    // (mkRoleVariables "VISUAL" apps.editor.gui)
    // (mkRoleVariables "FILE_MANAGER" apps.explorer);
}
