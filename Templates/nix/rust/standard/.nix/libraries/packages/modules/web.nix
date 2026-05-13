{lib, ...}: let
  inherit (lib.attrsets) optionalAttrs recursiveUpdate;
  inherit (lib.packages) mkBins mkBin;
in {
  mkWeb = {
    pkgs,
    variant ? {},
  }: let
    cfg =
      recursiveUpdate {
        kind = "integration";
        name = "web";
        enable = true;
        includeDeno = false;
        includePrettier = false;
        includeTrunk = false;
      }
      (optionalAttrs (variant ? web) variant.web);
  in
    {variant = cfg;}
    // optionalAttrs cfg.enable (let
      packages = with pkgs; let
        common =
          {}
          // optionalAttrs cfg.includeDeno {inherit deno;}
          // optionalAttrs cfg.includePnpm {inherit pnpm;}
          // optionalAttrs cfg.includePrettier {inherit prettierd;}
          // optionalAttrs cfg.includeTrunk {inherit trunk;};

        custom =
          (optionalAttrs cfg.includePnpm (
            mkBin {
              inherit pkgs;
              prefix = "pnpm-";
              set = {
                i = {command = "${pkgs.pnpm}/bin/pnpm install";};
                a = {script = ''${pkgs.pnpm}/bin/pnpm add "$@"'';};
                ad = {script = ''${pkgs.pnpm}/bin/pnpm add --save-dev "$@"'';};
              };
            }
          ))
          // (optionalAttrs cfg.includeDeno (
            mkBin {
              inherit pkgs;
              prefix = "deno-";
              set = {
                dev = {script = ''${pkgs.deno}/bin/deno task dev "$@"'';};
                run = {script = ''${pkgs.deno}/bin/deno run "$@"'';};
                lint = {command = "${pkgs.deno}/bin/deno lint";};
                fmt = {command = "${pkgs.deno}/bin/deno fmt";};
                test = {script = ''${pkgs.deno}/bin/deno test "$@"'';};
                check = {script = ''${pkgs.deno}/bin/deno check "$@"'';};
              };
            }
          ));
        all = common // custom;
      in {inherit all common custom;};

      binaries = let
        common = mkBins packages.common;
        custom = mkBins packages.custom;
        all = common // custom;
      in {inherit all common custom;};

      variables =
        {}
        # // optionalAttrs cfg.includeClaude
        # {ANTHROPIC_API_KEY = "$ANTHROPIC_API_KEY";}
        // {};
    in {inherit variables packages binaries;});
}
