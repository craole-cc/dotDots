{
  lib,
  inputs,
  pkgs,
  ...
}: let
  inherit (lib.shells)  mkRustSuite mkShells;
  inherit (lib.shells) ai;
  rustShells = mkRustSuite {inherit pkgs;};
  aiShells = ai.mkAISuite {inherit pkgs;};
  # combined = mkCombinedSuite {inherit pkgs;};
in {
  devShells = mkShells {
    inherit inputs;
    # default = combined.combined-common;
    # shells = rust // ai // combined;
    shells = rustShells // aiShells;
  };
}
