{ inputs }:
let
  system = builtins.currentSystem;
  pkgs = inputs.nixpkgs.legacyPackages.${system};
  lib = inputs.nixpkgs.lib;
  dib = inputs.self.DOTS.libs.extended;
in
{
  native = lib;
  extended = {
    filesystem = import ./filesystem.nix { inherit dib lib; };
    lists = import ./lists.nix { inherit dib lib; };
    fetchers = import ./fetchers.nix { inherit dib lib pkgs; };
  };
}
