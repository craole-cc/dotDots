{lib}: let
  inherit (lib.attrsets) attrValues;
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
    inputs,
    pkgs,
    fmt,
  }: let
    mk = args: let
      tools = mkTools ({inherit pkgs;} // args);
      inherit (tools) style;
      #TODO: It's the variants that should determine how this is called
      deployment = deployConfig ({inherit pkgs style;} // args);
      spec = mkSpec ({inherit pkgs;} // args);
      shell =
        spec.shell
        // {
          shellHook = ""; #TODO: Combined shellHook are currently too noisy
          packages =
            spec.shell.packages
            ++ (attrValues fmt.packages.${getSystem pkgs})
            ++ tools.packages
            ++ [deployment];
        };
    in
      spec // {inherit shell;};

    variants = {
      minimal = mk {};
      default = mk {
        includeExtras = true;
      };
      stable = mk {
        channel = "stable";
        includeExtras = true;
      };
      full = mk {
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
  mkDevShells = mkSuite;
}
