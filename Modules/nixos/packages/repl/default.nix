{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.repl = pkgs.callPackage ./pkg.nix { inherit lib; };
    };
}
