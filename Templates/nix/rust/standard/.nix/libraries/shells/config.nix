{lib}: let
  inherit (lib.attrsets) attrValues removeAttrs;
  inherit (lib.packages) getSystem;
  inherit
    (lib.shells)
    mergeNamespaces
    mkShells
    mkTools
    rust
    ai
    deployConfig
    ;

  combined = mergeNamespaces {inherit rust ai;};
  inherit (combined) mkSpec;

  mkSuite = {
    pkgs,
    fmt,
  }: {packages ? [], ...} @ args: let
    shellArgs = removeAttrs args ["packages"];
    tools = mkTools ({inherit pkgs;} // shellArgs);
    spec = mkSpec ({inherit pkgs;} // shellArgs);
    applicationPackages = tools.packages;
    shell =
      spec.shell
      // {
        shellHook = ""; #TODO: Combined shellHook are currently too noisy
        packages =
          spec.shell.packages
          ++ (attrValues fmt.packages.${getSystem pkgs})
          ++ applicationPackages
          ++ packages;
      };
  in
    spec // {inherit shell;};

  mkSuites = {
    inputs,
    pkgs,
    fmt,
  }: let
    suite = mkSuite {inherit pkgs fmt;};
    variants = {
      minimal = suite {
        packages = [
          (deployConfig {inherit pkgs;})
        ];
      };
      default = suite {
        packages = [
          (deployConfig {
            inherit pkgs;
            includeFormat = true;
            includeEditor = false;
            includeWeb = false;
          })
        ];
        includeExtras = true;
      };
      stable = suite {
        packages = [
          (deployConfig {
            inherit pkgs;
            includeFormat = true;
            includeEditor = false;
            includeWeb = false;
          })
        ];
        channel = "stable";
        includeExtras = true;
      };
      full = suite {
        packages = [
          (deployConfig {
            inherit pkgs;
            includeFormat = true;
            includeEditor = false;
            includeWeb = true;
          })
        ];
        includeExtras = true;
        includeWorkflow = true;
        includeWeb = true;
      };
    };
    namespaced = combined.mkSuite {inherit pkgs;};
  in {
    devShells = mkShells {
      inherit inputs;
      default = variants.minimal;
      shells = namespaced // variants;
    };
  };
in {
  inherit mkSpec mkSuite;
  inherit mkSuites;
  mkDevShells = mkSuites;
}
