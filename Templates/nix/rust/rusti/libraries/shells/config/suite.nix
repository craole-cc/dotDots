{lib}: let

  mkSuite = {
    inputs,
    pkgs,
  }: let
    inherit (lib.shells) mkShells ai rust;
    suites = {
      rust = rust.mkShells {inherit pkgs;};
      ai = ai.mkShells {inherit pkgs;};
      # full = combined.mkShells {inherit pkgs;};
    };
  in {
    devShells = mkShells {
      inherit inputs;
      default = suites.ai.ai-common;
      shells = suites.rust // suites.ai;
    };
  };
in {
  inherit mkSuite;
  mkDevShells = mkSuite;
}
