{lib}: let
  inherit (lib.attrsets) attrValues optionalAttrs;
  inherit (lib.packages) mkBins;
in {
  mkDatabase = {
    pkgs,
    variant ? {
      database = {
        enable = false;
        includeMysql = false;
        includePostgres = false;
        includeRedis = false;
        includeSqlite = false;
      };
    },
  }: let
    raw = variant.database or {};

    cfg = {
      enable = raw.enable or false;

      includeMysql =
        (raw.includeMysql or false)
        || (raw.enable or false);

      includePostgres =
        (raw.includePostgres or false)
        || (raw.enable or false);

      includeRedis =
        (raw.includeRedis or false)
        || (raw.enable or false);

      includeSqlite =
        (raw.includeSqlite or false)
        || (raw.enable or false);
    };
  in
    {
      kind = "database";
      all = [];
    }
    // optionalAttrs cfg.enable (let
      packages = with pkgs;
        {}
        // optionalAttrs cfg.includeMysql {inherit mysql-client;}
        // optionalAttrs cfg.includePostgres {inherit postgresql;}
        // optionalAttrs cfg.includeRedis {inherit redis;}
        // optionalAttrs cfg.includeSqlite {inherit sqlite;};

      binaries = {
        packages = mkBins packages;
        scripts = {};
        all = binaries.packages;
      };

      all = attrValues packages;
    in {inherit cfg packages binaries all;});
}
