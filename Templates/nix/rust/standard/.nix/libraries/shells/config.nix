{lib}: let
  inherit (lib.attrsets) attrValues listToAttrs;
  inherit (lib.packages) getSystem mkTreefmt;
  inherit
    (lib.shells)
    ai
    concatMap
    deployConfig
    mergeNamespaces
    mkShells
    mkTools
    rust
    ;

  combined = mergeNamespaces {inherit rust ai;};
  inherit (combined) mkSpec;

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
    mkFmt = shellArgs:
      mkTreefmt {
        inherit inputs self;
        includeRust = shellArgs.includeRust or false;
        includeWeb = shellArgs.includeWeb or false;
        includeExtras = shellArgs.includeExtras or false;
        includeDatabase = shellArgs.includeDatabase or false;
      };

    mkVariant = {
      shellArgs ? {},
      deployArgs ? {},
    }: let
      fmt = mkFmt shellArgs;
    in
      mkSuite {inherit pkgs fmt;} {inherit shellArgs deployArgs;};

    baseArgs = {
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

    baseDeployArgs = {
      minimal = {};
      default = {};
      stable = {};
      full = {includeWeb = true;};
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
    checks = listToAttrs (
      map (name: {
        inherit name;
        value = (mkFmt baseArgs.${name}).checks;
      })
      baseNames
    );
  };
in {
  inherit mkSpec mkSuite mkSuites;
  mkDevShells = mkSuites;
}
