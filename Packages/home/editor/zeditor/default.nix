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
    name = "zed-editor";
    kind = "editor";
    category = "gui";
    resolutionHints = ["zeditor" "zed-editor"];
    debug = true;
  };

  cfg = program {
    inherit (app) name package sessionVariables;
    extraConfig =
      {}
      # // import ./editor.nix
      # // import ./keybindings.nix
      # // import ./languages.nix
      # // import ./themes.nix
      // {};
  };
in {
  config = mkIf app.isAllowed cfg;
}
