{lib, ...}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.packages) mkBins;

  mkWeb = {
    pkgs,
    variant ? {web.enable = false;},
  }: let
    inherit (variant) web;
  in
    optionalAttrs web.enable (let
      packages = {
        inherit (pkgs) deno pnpm prettierd;
      };
      binaries = mkBins packages;
    in {
      kind = "web";
      inherit packages binaries;
    });
in {inherit mkWeb;}
