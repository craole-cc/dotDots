{
  config,
  lix,
  user,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;

  context = mkContext {
    inherit config;
    dom = "shells";
    sub = "tools";
    mod = "grep";
  };
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = user.applications.utilities.grep.enable or false;
    };
    outputs.programs = {
      ripgrep = {
        enable = true;
        arguments = [
          "--max-columns-preview"
          "--colors=line:style:bold"
        ];
      };

      ripgrep-all.enable = true;

      fd = {
        enable = true;
        extraOptions = ["--absolute-path"];
        ignores = [
          ".git/"
          "archives"
          "tmp"
          "temp"
          "*.bak"
        ];
      };
    };
  }
