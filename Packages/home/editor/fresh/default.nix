{
  lix,
  pkgs,
  user,
  config,
  ...
}: let
  inherit (lix.applications.generators) userApplicationConfig application program;
  # app = application {
  #   inherit user pkgs;
  #   name = "fresh-editor";
  #   kind = "editor";
  #   category = "tty";
  #   resolutionHints = ["fresh" "fresh-editor"];
  #   debug = true;
  # };
  app = userApplicationConfig {
    inherit config user pkgs;
    name = "fresh-editor";
    kind = "editor";
    category = "tty";
    resolutionHints = ["fresh" "fresh-editor"];
    debug = true;
  };
in {
  config = app;
}
