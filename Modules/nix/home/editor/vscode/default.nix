{
  config,
  lix,
  inputs,
  pkgs,
  user,
  toolkit,
  requires,
  fonts,
  paths,
  ...
}: let
  inherit (lix.applications.generators) userApplicationConfig;
  inherit (lix.modules.construction) mkConfig mkContext;

  context = mkContext {
    inherit config;
    dom = "editor";
    mod = "vscode";
    kind = "editor";
  };

  args =
    toolkit
    // {
      inherit (lix.attrsets.resolution) vscodePackage;
      inherit context fonts toolkit requires paths pkgs lix;
      inherit inputs;
      inherit (context) cfg;
      inherit (lix.attrsets.aggregation) mergeSafe;
      # inherit (lix.attrsets.construction) genAttrs;
      inherit (lix.options.construction) mkDefault mkEnable mkFalse mkTrue;
      # inherit (lix.lists.construction) optional;
      # inherit (lix.lists.predicates) isIn;
      # inherit (lix.strings.construction) optionalString;
      # # inherit bins config context entryAfter host inputs lix mkDefault mkEnable mkMerge paths pkgs style tools user;
      # fonts = mkFonts {inherit host user;};
      # requires = app: isIn app (user.applications.allowed or []);
    };
  inherit (args) mergeSafe mkEnable mkFalse mkTrue;

  profile = import ./settings args;
  build = import ./build (args // {profile = profile.output;});
  app = userApplicationConfig {
    inherit (import ./packages) customPackage extraPackages;
    inherit context user pkgs;
    name = "vscode";
    category = "gui";
    resolutionHints = [
      "code"
      "vscode"
      "vscode-fhs"
      "vscode-insiders"
    ];
    debug = false;
  };
in
  mkConfig {
    inherit context;
    options = mergeSafe [
      profile.options
      {
        enable = mkEnable {
          inherit context;
          condition = app.enable;
        };
        insiders = mkTrue "Whether to use Visual Studio Code Insiders instead of the standard release.";
        importJSON = mkFalse "Import fallback VS Code settings and keybindings from the saved JSON configuration.";
      }
    ];

    outputs = {
      home = app.home // build.activation;
    };
  }
