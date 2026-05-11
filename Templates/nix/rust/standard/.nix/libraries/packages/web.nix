{lib, ...}: let
  inherit (lib.attrsets) attrValues optionalAttrs;
  inherit (lib.packages) mkBin mkBins;
in {
  mkWeb = {
    pkgs,
    variant ? {
      web = {
        enable = false;
        includeDeno = false;
        includePrettier = false;
        includeTrunk = false;
        includePnpm = false;
      };
    },
  }: let
    raw = variant.web or {};

    cfg = {
      enable = raw.enable or false;

      includeDeno =
        raw.includeDeno or false
        || raw.enable or false;

      includePrettier =
        raw.includePrettier or false
        || raw.enable or false;

      includeTrunk =
        raw.includeTrunk or false;

      includePnpm =
        raw.includePnpm or false
        || raw.enable or false;
    };
  in
    {
      kind = "web";
      all = [];
    }
    // optionalAttrs cfg.enable (let
      packages =
        optionalAttrs cfg.includeDeno {inherit (pkgs) deno;}
        // optionalAttrs cfg.includePnpm {inherit (pkgs) pnpm;}
        // optionalAttrs cfg.includePrettier {inherit (pkgs) prettierd;}
        // optionalAttrs cfg.includeTrunk {inherit (pkgs) trunk;};

      scripts =
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

      binaries = {
        packages = mkBins packages;
        scripts = mkBins scripts;
        all = binaries.packages // binaries.scripts;
      };

      all = attrValues packages ++ attrValues scripts;
    in {inherit cfg packages scripts binaries all;});
}
