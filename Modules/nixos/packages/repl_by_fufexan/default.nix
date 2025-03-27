{
  systems = [ "x86_64-linux" ];

  perSystem =
    { pkgs, ... }:
    {
      packages = {
        # instant repl with automatic flake loading
        repl = pkgs.callPackage ./pkg.nix { };
      };
    };
}
