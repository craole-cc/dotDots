{
  lib,
  inputs,
  pkgs,
  ...
}: let
  inherit (lib.shells) mkShells mkRustSuite mkAISuite ;

  rust = mkRustSuite {inherit pkgs;};
  ai = mkAISuite {inherit pkgs;};
in {
  devShells = mkShells {
    inherit inputs;
    default = rust.rust-nightly-minimal;
    shells =  rust//ai;
  };
}
