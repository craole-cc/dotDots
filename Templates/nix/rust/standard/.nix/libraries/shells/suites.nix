{lib}: let
  inherit (lib.attrsets) attrValues listToAttrs;
  inherit (lib.packages) getSystem mkFmt mkChecks;
  inherit
    (lib.shells)
    mkVariants
    ai
    deployConfig
    mergeNamespaces
    mkShells
    mkTools
    rust
    ;
  inherit (lib.lists) concatMap;
  combined = mergeNamespaces {inherit rust ai;};
  inherit (combined) mkSpec;

  mkDevShell = {
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

  mkVariant = {
    shellArgs ? {},
    deployArgs ? {},
  }: let
    fmt = mkFmt {inherit inputs self;} shellArgs;
  in
    mkSuite {inherit pkgs fmt;} {inherit shellArgs deployArgs;};

  mkDevShells = {
    inputs,
    pkgs,
    self,
  }: let
    variants = mkVariants {
      inherit pkgs inputs self;
      raw = {
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
    };
    namespaced = combined.mkSuite {inherit pkgs;};
  in {
    devShells = mkShells {
      inherit inputs;
      default = variants.minimal;
      shells = namespaced // variants;
    };
    checks = mkChecks {
      bases = variants.raw;
      mkFmt = mkFmt {inherit inputs self;};
    };
    fmt = mkFmt variants.raw.default;
  };
in {inherit mkSpec mkDevShell mkDevShells;}
