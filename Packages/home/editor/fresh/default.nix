{
  config,
  lix,
  pkgs,
  user,
  ...
}: {
  inherit
    (lix.applications.generators.userApplicationConfig {
      inherit config user pkgs;
      name = "fresh-editor";
      kind = "editor";
      category = "tty";
      resolutionHints = ["fresh" "fresh-editor"];
      debug = true;
    })
    home
    programs
    ;
}
