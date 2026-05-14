{lib, ...}: let
  inherit (lib.attrsets) optionalAttrs recursiveAttrs;
  inherit (lib.packages) mkBins mkBin;
in {
  mkWeb = {
    pkgs,
    variant ? {},
  }: let
    name = "web";
    cfg = let
      set1 = {
        inherit name;
        kind = "integration";
        enable = false;
        includeDeno = false;
        includePnpm = false;
        includeTrunk = false;
      };
      set2 = variant.web or {};
      set3 = recursiveAttrs {inherit set1 set2;};
      set4 = {};
    in {
      inherit set1 set2 set3 set4;
      final = recursiveAttrs {inherit set3 set4;};
    };
    configuration = cfg.final;
  in
    {inherit configuration;}
    // optionalAttrs configuration.enable (with configuration; let
      packages = let
        common = with pkgs;
          {}
          // optionalAttrs includeDeno {inherit deno;}
          // optionalAttrs includePnpm {inherit pnpm;}
          // optionalAttrs includeTrunk {inherit trunk;};

        custom =
          optionalAttrs includePnpm (
            mkBin {
              inherit pkgs;
              prefix = "pnpm";
              sep = "-";
              set = {
                i = {command = "pnpm install";};
                a = {script = ''pnpm add "$@"'';};
                ad = {script = ''pnpm add --save-dev "$@"'';};
              };
            }
          )
          // optionalAttrs includeDeno (
            mkBin {
              inherit pkgs;
              prefix = "deno";
              sep = "-";
              set = {
                dev = {script = ''deno task dev "$@"'';};
                run = {script = ''deno run "$@"'';};
                lint = {command = "deno lint";};
                fmt = {command = "deno fmt";};
                test = {script = ''deno test "$@"'';};
                check = {script = ''deno check "$@"'';};
              };
            }
          );
        all = common // custom;
      in {inherit all common custom;};

      binaries = let
        common = mkBins packages.common;
        custom = mkBins packages.custom;
        all = common // custom;
      in {inherit all common custom;};

      variables = {};
      messages = null;
    in {inherit variables packages binaries messages;});
}
