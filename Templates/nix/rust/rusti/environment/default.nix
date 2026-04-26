{
  lib,
  inputs,
  pkgs,
  ...
}: let
  inherit (lib.shells) mkShells mkRustSuite;

  rust = mkRustSuite {inherit pkgs;};
  # ai = mkAISuite {inherit pkgs;};
in {
  devShells = mkShells {
    inherit inputs;
    default = rust.rust-nightly-minimal;
    shells =  rust;
  };
}
