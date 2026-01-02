{
  lib,
  lix,
  user,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lix.applications.generators) application program;

  app = application {
    inherit user pkgs;
    name = "helix";
    kind = "editor";
    category = "tty";
    resolutionHints = ["hx" "helix" "helix-editor"];
  };

  cfg = program {
    inherit (app) name package sessionVariables;
    extraConfig =
      {defaultEditor = app.isPrimary;}
      // import ./editor.nix
      // import ./keybindings.nix
      // import ./languages.nix
      // import ./themes.nix
      // {};
  };
in {
  config = mkIf app.isAllowed cfg;
}
