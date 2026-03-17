{lib, ...}: let
  inherit (lib.modules) mkMerge mkDefault;
in
  mkMerge [
    (import ./bindings.nix {})
    (import ./editor.nix {inherit mkDefault;})
    (import ./files.nix {})
    (import ./git.nix {})
    (import ./global.nix {})
    (import ./terminal.nix {inherit mkDefault;})
  ]
