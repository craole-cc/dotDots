{
  config,
  lix,
  inputs,
  pkgs,
  user,
  ...
}: let
  inherit (lix.applications.generators) userApplicationConfig;
  inherit (lix.attrsets.aggregation) mergeSafe;
  inherit (lix.attrsets.construction) genAttrs;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable mkFalse mkTrue;
  # inherit (lix.lists.construction) optional;
  # inherit (lix.lists.predicates) isIn;
  # inherit (lix.schema.fonts) mkFonts;
  inherit (lix.sources.packages) pkgsFrom;
  # inherit (lix.strings.construction) optionalString;

  context = mkContext {
    inherit config;
    dom = "editor";
    mod = "vscode";
    kind = "editor";
  };
  inherit (context) cfg;

  args = let
    tools = pkgsFrom {
      inherit inputs pkgs;
      sources = {
        coreutils = null;
        jaq = null;
        vscode-fhs = null;
        vscode-insiders =
          if cfg.insiders
          then "vscode-insiders"
          else null;
      };
      required = true;
    };
    bins = let
      coreutils =
        genAttrs ["chmod" "cp" "dirname" "install" "mkdir" "rm"]
        (command: "${tools.coreutils.paths.binary}/${command}");
    in
      mergeSafe [
        coreutils
        tools.binaries
        {
          rmf = "${coreutils.rm} -rf";
          cpa = "${coreutils.cp} -a --reflink=auto";
          chmodr = "${coreutils.chmod} -R";
          mkdir = "${coreutils.mkdir} -p";
          mktempd = "${coreutils.mkdir} -d";
          mv = "${coreutils.mv} -T";
          lnsfn = "${coreutils.ln} -sfn";
        }
      ];
  in {
    inherit (lix.attrsets.resolution) vscodePackage;
    inherit tools bins;
    # # inherit bins config context entryAfter host inputs lix mkDefault mkEnable mkMerge paths pkgs style tools user;
    # fonts = mkFonts {inherit host user;};
    # requires = app: isIn app (user.applications.allowed or []);
    json = pkgs.formats.json {}; # Move to an appropriate lib
  };

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
