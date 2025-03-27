{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.frepl = pkgs.callPackage ./pkg.nix { inherit lib; };
    };
}
