{ lib, ... }:
let
  inherit (lib.attrsets) optionalAttrs;

  mkDatabase =
    set:
    optionalAttrs set.enable (
      { }
      // optionalAttrs set.includePostgres {
        postgres = {
          source = ./postgres.conf;
          target = "postgres.conf";
        };
      }
      // optionalAttrs set.includeMysql {
        mysql = {
          source = ./my.cnf;
          target = "my.cnf";
        };
      }
      // optionalAttrs set.includeSqlite {
        sqlite = {
          source = ./sqlite.db;
          target = "sqlite.db";
        };
      }
      // optionalAttrs set.includeRedis {
        redis = {
          source = ./redis.conf;
          target = "redis.conf";
        };
      }
    );
in
{
  inherit mkDatabase;
}
