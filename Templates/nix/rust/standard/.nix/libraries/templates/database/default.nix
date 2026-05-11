{lib, ...}: let
  inherit (lib.attrsets) optionalAttrs;

  mkDatabase = set:
    optionalAttrs (set != null) (
      {}
      // optionalAttrs (set.includePostgres or false) {
        postgres = {
          source = ./postgres.conf;
          target = "postgres.conf";
        };
      }
      // optionalAttrs (set.includeMysql or false) {
        mysql = {
          source = ./my.cnf;
          target = "my.cnf";
        };
      }
      // optionalAttrs (set.includeSqlite or false) {
        sqlite = {
          source = ./sqlite.db;
          target = "sqlite.db";
        };
      }
      // optionalAttrs (set.includeRedis or false) {
        redis = {
          source = ./redis.conf;
          target = "redis.conf";
        };
      }
    );
in {inherit mkDatabase;}
