{
  config,
  lix,
  user,
  pkgs,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lix.applications.registry) resolve;
  inherit (lix.applications.runtime) resolvePackage;
  inherit (lix.attrsets.construction) listToAttrs;
  inherit (lix.lists.predicates) elem;
  inherit (lix.lists.selection) filter;
  inherit (lix.strings.construction) toJSON;

  context = mkContext {
    inherit config;
    dom = "browser";
    mod = "chromium";
  };

  selections = user.packages.browser or ((lix.schema.packages.resolve {record = user;}).browser or []);
  supported = ["chromium" "brave" "google-chrome" "google-chrome-beta" "google-chrome-dev" "vivaldi" "microsoft-edge"];
  browsers = filter (app: elem app.names.package supported) (map (value:
    resolve {
      inherit value;
      category = "browser";
    })
  selections);
  enable = browsers != [];

  common = (import ./cli.nix) // (import ./extensions.nix);
  programs = listToAttrs (map (app: {
      name = app.names.package;
      value =
        common
        // {
          enable = true;
          package = resolvePackage {inherit app pkgs;};
        };
    })
    browsers);
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        inherit context;
        condition = enable;
      };
    };
    outputs = {
      inherit programs;
      home.sessionVariables._dbg_CHROMIUM = toJSON (map (app: app.name) browsers);
    };
  }
