{lib}: let
  inherit (lib.attrsets) attrValues listToAttrs;
  inherit (lib.packages) getSystem mkFmt mkChecks;
  inherit
    (lib.shells)
    ai
    deployConfig
    mergeNamespaces
    mkShells
    mkTools
    rust
    setMarker
    ;
  inherit (lib.lists) concatMap;
  combined = mergeNamespaces {inherit rust ai;};
  inherit (combined) mkSpec;

  project = rec {
    anchor = setMarker {};
    name = baseNameOf anchor;
  };

  mkSuite = {
    pkgs,
    fmt,
  }: {
    shellArgs ? {},
    deployArgs ? {},
    extraPackages ? [],
    ...
  }: let
    tools = mkTools ({inherit pkgs;} // shellArgs);
    spec = mkSpec ({inherit pkgs;} // shellArgs);
    applicationPackages = tools.packages;
    deploymentPackage = deployConfig ({inherit pkgs;} // deployArgs);
    shell =
      spec.shell
      // {
        shellHook = "";
        packages =
          spec.shell.packages
          ++ (attrValues fmt.packages.${getSystem pkgs})
          ++ applicationPackages
          ++ [deploymentPackage]
          ++ extraPackages;
      };
  in
    spec // {inherit shell;};

  mkSuites = {
    inputs,
    pkgs,
    self,
  }: let
    mkVariant = {
      shellArgs ? {},
      deployArgs ? {},
    }: let
      fmt = mkFmt {inherit inputs self;} shellArgs;
    in
      mkSuite {inherit pkgs fmt;} {inherit shellArgs deployArgs;};

    base = let
      shell = {
        minimal = {};
        default = {includeExtras = true;};
        stable = {
          channel = "stable";
          includeExtras = true;
        };
        full = {
          includeExtras = true;
          includeWorkflow = true;
          includeWeb = true;
          includeDatabase = true;
          includeRust = true;
        };
      };
    in
      mapAttrs (_: args: mkEnvVariant args) {
        minimal = {};
        default = {includeExtras = true;};
        stable = {
          channel = "stable";
          includeExtras = true;
        };
        full = {
          includeExtras = true;
          includeWorkflow = true;
          includeWeb = true;
          includeDatabase = true;
          includeRust = true;
        };
      };

    baseVariants = {
      minimal = mkVariant {shellArgs = baseArgs.minimal;};
      default = mkVariant {shellArgs = baseArgs.default;};
      stable = mkVariant {shellArgs = baseArgs.stable;};
      full = mkVariant {shellArgs = baseArgs.full;};
    };

    editorNames = ["vscode" "helix" "zed" "rustrover" "neovim"];
    editorSuffixes = {
      vscode = "Vscode";
      helix = "Helix";
      zed = "Zed";
      rustrover = "Rustrover";
      neovim = "Neovim";
    };
    baseNames = ["minimal" "default" "stable" "full"];

    editorVariants = listToAttrs (
      concatMap (
        baseName:
          map (
            editorName: {
              name = "${baseName}With${editorSuffixes.${editorName}}";
              value = mkVariant {
                shellArgs = baseArgs.${baseName} // {includeEditor = true;};
                deployArgs = baseDeployArgs.${baseName} // {withEditor = editorName;};
              };
            }
          )
          editorNames
      )
      baseNames
    );

    variants = baseVariants // editorVariants;
    namespaced = combined.mkSuite {inherit pkgs;};
  in {
    devShells = mkShells {
      inherit inputs;
      default = variants.minimal;
      shells = namespaced // variants;
    };
    checks = mkChecks {
      bases = baseArgs;
      mkFmt = mkFmt {inherit inputs self;};
    };
    fmt = mkFmt baseArgs.default;
  };
in {inherit project mkSpec mkSuite mkSuites;}
