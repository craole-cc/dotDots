{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = {
        frepl = pkgs.callPackage ./repl { inherit lib; };
        repl = pkgs.callPackage ./repl_by_fufexan { inherit lib; };
      };
    };
}
