{
  top,
  apps,
  lix,
  ...
}: let
  inherit (lix.attrsets.access) foldlAttrs;
  inherit (lix.lists.construction) concatLists;
  inherit (lix.lists.access) last;
  inherit (lix.lists.aggregation) foldl';
  inherit (lix.lists.predicates) all;
  inherit (lix.options.construction) mkOption mkOptionType;
  inherit (lix.types.primitives) anything;
  inherit (lix.types.predicates) isAttrs isList;
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.modules.construction) mkDefault;

  mkRoleVariables = prefix: set:
    foldlAttrs (
      acc: role: suffix: let
        entry = set.${role} or null;
      in
        acc
        // optionalAttrs
        (isAttrs entry && (entry.command or null) != null)
        {
          "${prefix}_${suffix}" = mkDefault entry.command;
          "${prefix}_${suffix}_NAME" = mkDefault entry.name;
        }
    ) {} {
      primary = "PRI";
      secondary = "SEC";
      tertiary = "TER";
    };

  primaryVariables =
    optionalAttrs
    (isAttrs (apps.terminal.primary or null))
    {TERMINAL = mkDefault apps.terminal.primary.command;}
    // optionalAttrs
    (isAttrs (apps.browser.primary or null))
    {BROWSER = mkDefault apps.browser.primary.command;}
    // optionalAttrs
    (isAttrs (apps.editor.tty.primary or null))
    {EDITOR = mkDefault apps.editor.tty.primary.command;}
    // optionalAttrs
    (isAttrs (apps.editor.gui.primary or null))
    {VISUAL = mkDefault apps.editor.gui.primary.command;}
    // optionalAttrs
    (isAttrs (apps.explorer.primary or null))
    {FILE_MANAGER = mkDefault apps.explorer.primary.command;};

  mergeOutput = values:
    if all isAttrs values
    then
      foldl' (
        merged: value:
          foldlAttrs (
            result: name: item:
              result
              // {
                ${name} =
                  if result ? ${name}
                  then
                    mergeOutput [
                      result.${name}
                      item
                    ]
                  else item;
              }
          )
          merged
          value
      ) {}
      values
    else if all isList values
    then concatLists values
    else last values;

  outputType = mkOptionType {
    name = "home output";
    description = "recursively merged Home Manager output";
    check = _: true;
    merge = _: definitions: mergeOutput (map (definition: definition.value) definitions);
  };
in {
  options.${top} = {
    defaults = mkOption {
      description = "Schema-derived default dotDots input values";
      default = {};
      type = anything;
    };
    updates = mkOption {
      description = "Sparse dotDots input values differing from defaults";
      default = {};
      type = anything;
    };
    outputs = mkOption {
      description = "Sparse effective Home Manager configuration outputs";
      default = {};
      type = outputType;
    };
  };

  # One normalized application-role contract for the session. Leaf modules may
  # provide stronger package-specific values; these defaults fill every role
  # name consistently, including tertiary and file-manager roles.
  config.home.sessionVariables =
    primaryVariables
    // (mkRoleVariables "TERMINAL" apps.terminal)
    // (mkRoleVariables "BROWSER" apps.browser)
    // (mkRoleVariables "EDITOR" apps.editor.tty)
    // (mkRoleVariables "VISUAL" apps.editor.gui)
    // (mkRoleVariables "FILE_MANAGER" apps.explorer);

  imports = (lix.filesystem.traversal.importAllPaths ./.).value;

  # # Home is being migrated incrementally to the same mkContext/mkConfig
  # # contract as Core. Only migrated modules are wired here; the legacy tree
  # # remains available for staged conversion without participating in eval.
  # imports = [
  #   # ./ai/runtime.nix
  #   # ./applications
  #   ./interface/options.nix
  #   ./interface/catppuccin.nix
  #   ./interface/dms.nix
  #   ./interface/manager/hyprland

  #   # Browsers
  #   ./browser/chromium
  #   ./browser/zen

  #   # Editors
  #   ./editor/helix
  #   ./editor/nvim
  #   ./editor/vim
  #   ./editor/vscode
  #   ./editor/zeditor

  #   # Information utilities
  #   ./info/btop.nix
  #   ./info/clock.nix
  #   ./info/fetchers.nix

  #   # Media
  #   ./media/editing
  #   ./media/freetube
  #   ./media/mpv
  #   ./media/obs

  #   # Shells
  #   ./shells/core/bash
  #   ./shells/core/fish
  #   ./shells/core/nushell
  #   ./shells/core/zsh
  #   ./shells/prompt/starship.nix

  #   # Shell tools
  #   ./shells/tools/atuin.nix
  #   ./shells/tools/bat.nix
  #   ./shells/tools/direnv.nix
  #   ./shells/tools/grep.nix
  #   ./shells/tools/home-manager.nix
  #   ./shells/tools/nh.nix
  #   ./shells/tools/nix-index.nix
  #   ./shells/tools/topgrade.nix
  #   ./shells/tools/yazi.nix

  #   # Terminals
  #   ./terminal/core/foot
  #   ./terminal/core/ghostty
  #   ./terminal/core/kitty
  #   ./terminal/tools/tmux

  #   # Version control
  #   ./version-control/core/git.nix
  #   ./version-control/core/jujutsu.nix
  #   ./version-control/clients/github.nix
  #   ./version-control/clients/gitui.nix
  #   ./version-control/tools/delta.nix
  # ];
}
