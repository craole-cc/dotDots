{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.zfs-root.per-user.craole.modules.emacs;
  inherit (lib) mkDefault mkOption types mkIf;
  # buildEmacs is a function that takes a set of emacs packages as input
  buildEmacs = (pkgs.emacsPackagesFor pkgs.emacs).emacsWithPackages;
  emacsPkg = buildEmacs (epkgs:
    builtins.attrValues {
      inherit (epkgs.melpaPackages) nix-mode notmuch;
      inherit (epkgs.elpaPackages) use-package auctex pyim pyim-basedict;
    });
in {
  options.zfs-root.per-user.craole.modules.emacs = {
    enable = mkOption {
      type = types.bool;
      default = config.zfs-root.per-user.craole.enable;
    };
    extraPackages = mkOption {
      description = "normal software packages that emacs depends to run";
      type = types.listOf types.package;
      default = builtins.attrValues {
        inherit
          (pkgs)
          # spell checkers
          
          enchant
          nuspell
          # used with dired mode to open files
          
          xdg-utils
          ;
        inherit (pkgs.hunspellDicts) en_US de_DE;
        inherit emacsPkg;
      };
    };
  };
  config = mkIf (cfg.enable) {
    environment = {
      systemPackages = cfg.extraPackages;
      interactiveShellInit = ''
        export EDITOR="emacsclient --alternate-editor= --create-frame -nw"
        e () { $EDITOR "$@"; }
      '';
    };
  };
}
