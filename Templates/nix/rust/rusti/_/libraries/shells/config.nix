{lib}: let
  inherit (lib.shells) mergeNamespaces mkShells rust ai;

  combined = mergeNamespaces {inherit rust ai;};
  inherit (combined) mkSpec;

  mkSuite = {
    inputs,
    pkgs,
  }: let
    mk = args: mkSpec ({inherit pkgs;} // args);
    variants = {
      default = mk {};
      stable = mk {channel = "stable";};
      full = mk {
        preset = "full";
        includeWorkflow = true;
      };
      minimal = mk {
        preset = "minimal";
        includeAnalytics = false;
        includeEditor = false;
        minimal = true;
      };
    };
    namespaced = combined.mkSuite {inherit pkgs;};
  in {
    devShells = mkShells {
      inherit inputs;
      default = variants.default;
      shells = namespaced // variants;
    };
  };
in {
  inherit mkSpec mkSuite;
  mkDevShells = mkSuite;
}
