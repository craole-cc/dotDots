let
  inherit (builtins) getFlake isAttrs pathExists;

  mkTemplate = arg: let
    spec =
      if isAttrs arg
      then arg
      else {path = arg;};

    inherit (spec) path;
    description = spec.description or "";

    hasFlake = pathExists (path + "/flake.nix");
  in {
    inherit path;
    description =
      if hasFlake
      then (getFlake (toString path)).description or description
      else description;
  };

  templates = {
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
    # rust = mkTemplate {
    #   path = ./rust/standard;
    #   description = "Rust development environment with nightly toolchain";
    # };
    rust = mkTemplate ./rust/rusti;
    # rustspace = mkTemplate {
    #   path = ./rust/workspace;
    #   description = "Rust workspace with multiple crates";
    # };
  };
in templates // {default = templates.rust;}
