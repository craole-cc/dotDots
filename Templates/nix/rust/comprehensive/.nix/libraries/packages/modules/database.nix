{lib}: let
  inherit (lib.attrsets) optionalAttrs recursiveAttrs recursiveUpdate;
  inherit (lib.packages) mkBins;
in {
  mkDatabase = {
    pkgs,
    variant ? {},
  }: let
    cfg = recursiveAttrs {
      "1" = {
        kind = "integration";
        name = "database";
        enable = false;
        includeMysql = false;
        includePostgres = false;
        includeRedis = false;
        includeSqlite = false;
      };
      "2" = variant.db;
    };
    # cfg =
    #   recursiveUpdate {
    #     kind = "integration";
    #     name = "database";
    #     enable = false;
    #     includeMysql = false;
    #     includePostgres = false;
    #     includeRedis = false;
    #     includeSqlite = false;
    #   }
    #   (optionalAttrs (variant ? db) variant.db);
  in
    {configuration = cfg;}
    // optionalAttrs cfg.enable (let
      packages = let
        common = with pkgs;
          {}
          // optionalAttrs cfg.includeMysql {inherit (mariadb) client;}
          // optionalAttrs cfg.includePostgres {inherit postgresql;}
          // optionalAttrs cfg.includeRedis {inherit redis;}
          // optionalAttrs cfg.includeSqlite {inherit sqlite;};

        custom = {};
        all = common // custom;
      in {inherit all common custom binaries;};

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
