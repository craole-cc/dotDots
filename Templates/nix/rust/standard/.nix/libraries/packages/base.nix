{lib, ...}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.packages) mkBins;

  mkBase = {
    pkgs,
    variant ? {
      base = {
        enable = true;
        includeMise = false;
      };
    },
  }: let
    inherit (variant) base;
  in (
    {kind = "base";}
    // optionalAttrs base.enable (let
      packages = with pkgs;
        {
          inherit
            bat
            direnv
            fd
            git
            gnused
            gum
            jq
            nixd
            ripgrep-all
            sd
            trashy
            undollar
            ;
          inherit gcc rust-script;
        }
        // optionalAttrs includeMise {inherit mise;};
      binaries = mkBins packages;
    in {inherit packages binaries;})
  );
in {inherit mkBase;}
