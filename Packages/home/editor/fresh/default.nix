{
  lib,
  lix,
  pkgs,
  user,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lix.applications.generators) application program;

  app = application {
    inherit user pkgs;
    name = "fresh-editor";
    kind = "editor";
    category = "tty";
    resolutionHints = ["fresh" "fresh-editor"];
    debug = true;
  };

  cfg = program {inherit (app) name package sessionVariables;};
in {
  config = mkIf app.isAllowed cfg.home;
}
