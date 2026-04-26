{lib}: let
  mkSuites = {
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
      # default = suites.full;
      shells = suites.rust // suites.ai;
    };
  };
in {
  inherit mkSuites;
  mkDevShells = mkSuites;
}
