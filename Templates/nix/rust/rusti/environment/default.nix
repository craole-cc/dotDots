{
  lib,
  inputs,
  pkgs,
  ...
}: let
  inherit (lib.shells) mkAISuite mkRustSuite mkShells;
  rust = mkRustSuite {inherit pkgs;};
  ai = mkAISuite {inherit pkgs;};
  # combined = mkCombinedSuite {inherit pkgs;};
in {
  devShells = mkShells {
    inherit inputs;
    # default = combined.combined-common;
    # shells = rust // ai // combined;
    shells = rust // ai;
  };
}
