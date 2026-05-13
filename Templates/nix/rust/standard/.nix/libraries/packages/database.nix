{lib}: let
  inherit (lib.attrsets) attrValues optionalAttrs;
  inherit (lib.packages) mkBins;
  inherit (lib.strings) toJSON toUpper;
in {
  mkDatabase = {
    pkgs,
    variant ? {},
  }: let
    kind = "database";
    cfg =
      variant.${
        kind
      } or {
        enable = false;
        includeMysql = false;
        includePostgres = false;
        includeRedis = false;
        includeSqlite = false;
      };
    env = {"__VARIANT_${toUpper kind}" = toJSON cfg;};
    all = [];
  in
    {inherit all kind env;}
    // optionalAttrs cfg.enable (let
      packages = let
        common = with pkgs;
          {}
          // optionalAttrs cfg.includeMysql {inherit (mariadb) client;}
          // optionalAttrs cfg.includePostgres {inherit postgresql;}
          // optionalAttrs cfg.includeRedis {inherit redis;}
          // optionalAttrs cfg.includeSqlite {inherit sqlite;};

        custom = {};
        all = attrValues common ++ attrValues custom;
      in {inherit all common custom binaries;};

      binaries = let
        common = mkBins packages.common;
        custom = mkBins packages.custom;
        all = common // custom;
      in {inherit all common custom;};
    in {inherit cfg packages binaries;});
}
