{lib}: let
  inherit (lib.attrsets) optionalAttrs recursiveAttrs;
  inherit (lib.packages) mkBins mkBin mkPkg;
in {
  mkDatabase = {
    pkgs,
    variant ? {},
  }: let
    name = "database";
    cfg = let
      set1 = {
        inherit name;
        kind = "integration";
        enable = false;
        includeMysql = false;
        includePostgres = false;
        includeMariaDB = false;
        includeSqlite = false;
      };
      set2 = variant.db or {};
      set3 = recursiveAttrs {inherit set1 set2;};
      set4 = {
        includeMariaDB = with set3; includeMariaDB || includeMysql;
      };
    in {
      inherit
        set1
        set2
        set3
        set4
        ;
      final = recursiveAttrs {inherit set3 set4;};
    };
    configuration = cfg.final;
  in
    {
      inherit configuration;
    }
    // optionalAttrs configuration.enable (
      with configuration; let
        packages = let
          common = with pkgs;
            {}
            // optionalAttrs includePostgres {inherit postgresql;}
            // optionalAttrs includeSqlite {inherit sqlite;}
            // optionalAttrs includeMariaDB {inherit (mariadb) client;};

          custom = with binaries.common;
            {}
            // optionalAttrs includePostgres (mkBin {
              inherit pkgs;
              prefix = "pg";
              sep = "-";
              set = {
                connect = {
                  script = ''${postgresql}/bin/psql "$@"'';
                };
                dump = {
                  script = ''${postgresql}/bin/pg_dump "$@"'';
                };
                restore = {
                  script = ''${postgresql}/bin/pg_restore "$@"'';
                };
                start = {
                  script = ''${postgresql}/bin/pg_ctl start "$@"'';
                };
                stop = {
                  script = ''${postgresql}/bin/pg_ctl stop "$@"'';
                };
                status = {
                  command = "${postgresql}/bin/pg_ctl status";
                };
              };
            })
            // optionalAttrs includeMariaDB (mkBin {
              inherit pkgs;
              prefix = "my";
              sep = "-";
              set = {
                connect = {
                  script = ''${mysql}/bin/mysql "$@"'';
                };
                dump = {
                  script = ''${mysqldump}/bin/mysqldump "$@"'';
                };
                import = {
                  script = ''${mysql}/bin/mysql "$@" < /dev/stdin'';
                };
                start = {
                  script = ''${mysqld_safe}/bin/mysqld_safe "$@" &'';
                };
              };
            })
            // optionalAttrs includeSqlite {
              sql = mkPkg {
                inherit pkgs;
                name = "sql";
                script = ''${sqlite} "$@"'';
              };
            }
            // optionalAttrs includeSqlite (mkBin {
              inherit pkgs;
              prefix = "sql";
              sep = "-";
              set = {
                tables = {
                  script = ''${sqlite} "$1" ".tables"'';
                };
                schema = {
                  script = ''${sqlite} "$1" ".schema"'';
                };
              };
            });

          all = common // custom;
        in {
          inherit all common custom;
        };

        binaries = let
          common =
            mkBins packages.common
            // optionalAttrs includePostgres (
              with pkgs; {
                psql = "${postgresql}/bin/psql";
                pg_dump = "${postgresql}/bin/pg_dump";
                pg_restore = "${postgresql}/bin/pg_restore";
                pg_ctl = "${postgresql}/bin/pg_ctl";
              }
            )
            // optionalAttrs includeMariaDB (
              with pkgs.mariadb; {
                mysql = "${client}/bin/mysql";
                mysqldump = "${client}/bin/mysqldump";
                mysqld_safe = "${client}/bin/mysqld_safe";
              }
            );
          custom = mkBins packages.custom;
          all = common // custom;
        in {
          inherit all common custom;
        };

        variables = {};
        messages = null;
      in {
        inherit
          variables
          packages
          binaries
          messages
          ;
      }
    );
}
