{lib}: let
  inherit (lib.shells) mergeSpecs mkShells rust ai;

  combined = mergeSpecs {inherit rust ai;};
  mkSpec = combined.mkShell;

  mkSuite = {
    inputs,
    pkgs,
    lib ? null,
  }: let
    mk = args: mkSpec ({inherit pkgs;} // args);
    individuals = combined.mkSuite {inherit pkgs;};
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
  in {
    devShells = mkShells {
      inherit inputs;
      default = variants.default;
      shells = individuals // variants;
    };
  };
in {
  inherit mkSpec mkSuite;
  mkDevShells = mkSuite;
}
