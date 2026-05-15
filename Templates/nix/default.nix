let
  inherit (builtins) isAttrs pathExists;

  mkTemplate = arg: let
    spec =
      if isAttrs arg
      then arg
      else {path = arg;};

    inherit (spec) path;
    description = spec.description or "";

    hasFlake = pathExists (path + "/flake.nix");
  in {inherit path description;};

  templates =
    {
      common = mkTemplate {
        path = ./common;
        description = "Common development utilities";
      };
      dev = mkTemplate {
        path = ./dev;
        description = "Common development utilities";
      };
      media = mkTemplate {
        path = ./media;
        description = "Comprehensive Media Environment";
      };
      rust = mkTemplate {
        path = ./rust/comprehensive;
        description = "Rust development environment with AI Tools";
      };
      rustspace = mkTemplate {
        path = ./rust/workspace;
        description = "Rust workspace with multiple crates";
      };
    }
    // {
      default = templates.rust;
    };
in
  templates
