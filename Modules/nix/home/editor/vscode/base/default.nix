{lib, ...}: let
  inherit (lib.modules) mkMerge mkDefault;

  bindings = import ./bindings.nix {};
  editor = import ./editor.nix {inherit mkDefault;};
  files = import ./files.nix {};
  global = import ./global.nix {};
  terminal = import ./terminal.nix {inherit mkDefault;};
in
  mkMerge [
    {
      userSettings = mkMerge [
        editor.userSettings
        terminal.userSettings
        files.userSettings
        global.userSettings
      ];
    }
    {inherit (bindings) keybindings;}
  ]
