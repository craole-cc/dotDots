{
  lib,
  inputs,
  ...
}: let
  inherit (lib.shells) mkShells;

  testShell = {
    name = "ai-rust";
    packages = [];
    env = {};
    shellHook = ''
      echo "🔧 AI+Rust REPL"
      echo "REPL: nix repl"
    '';
  };
in {
  devShells = mkShells {
    inherit inputs;
    default = testShell;
    shells = {inherit testShell;};
  };
}
