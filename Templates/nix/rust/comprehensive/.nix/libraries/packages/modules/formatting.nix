{lib}: let
  inherit
    (lib.attrsets)
    filterAttrs
    mapAttrs
    optionalAttrs
    updateAttrs
    recursiveUpdate
    recursiveAttrs
    ;
  inherit (lib.lists) elem toList;
  inherit
    (lib.packages)
    defineSystems
    getSystemOrDefault
    mkBins
    perSystem
    resolvePackages
    ;

  mkFormatter = {
    inputs,
    pkgs,
    variant ? {},
    projectRootFile ? null,
  }:
    mkTreefmt {inherit inputs pkgs projectRootFile variant;};

  mkChecker = {
    inputs,
    self,
    variant ? {},
    projectRootFile ? null,
  }:
    perSystem {
      inherit inputs;
      fn = pkgs: {
        formatting =
          (mkTreefmt {
            inherit inputs pkgs projectRootFile variant;
          }).check
          self;
      };
    };

  mkTreefmt = {
    inputs,
    pkgs,
    variant,
    projectRootFile ? "flake.nix",
  }: let
    system = getSystemOrDefault {inherit pkgs;};
    inherit (resolvePackages {inherit inputs;}) treefmt;

    cfg = let
      a = {
        enable = true;
        kind = "workflow";
        name = "formatter";
        includeAlejandra = true;
        includeDeno = false;
        includePrettier = false;
        includeRustfmt = false;
        includeLeptosfmt = false;
        includeSQLfmt = false;
        incudeSQLruff = false;
      };
      b = variant.fmt;
      c = {
        includeRust = with variant.rust; enable && includeFmt;
        includeLeptos = with variant.rust; enable && includeFmt && includeLeptos;
        includeDeno = with variant.web; enable && includeDeno && for.allBut "riscv64-linux";
        includePrettier = with variant.web; enable && includePrettier;
        # includeSQLfmt = with variant.db.enable && !(incudeSQLruff);
        # includeSqlite = with variant.db; enable && (includeSqlite || includePostgres );
        includePostgres = with variant.db; enable && includePostgres;
        includeMysql = with variant.db; enable && includeMysql;
      };
    in
      recursiveAttrs {inherit a b c;};

    for = {
      allBut = systems: !(elem system (toList systems));
      all = {systems ? defineSystems}: elem system (toList systems);
    };

    sqlFormatterSettings =
      mapAttrs
      (_: sqlCfg: {
        command = "${pkgs.sql-formatter}/bin/sql-formatter";
        options =
          ["--language" sqlCfg.dialect] # TODO: Validate this option
          ++ (sqlCfg.options or []);
        includes = sqlCfg.includes or ["*.sql"];
        excludes = sqlCfg.excludes or [];
        priority = sqlCfg.priority or 0; # TODO: Validate this option
      })
      (
        filterAttrs
        (_: sqlCfg: sqlCfg.enable or false)
        (cfg.sqlFormatters or {})
      );

    programs =
      {
        actionlint.enable = true;
        alejandra.enable = for.all {};
        shellcheck.enable = true;
        shfmt.enable = true;
        statix.enable = true;
        taplo.enable = true;
        yamlfmt.enable = true;
      }
      // optionalAttrs cfg.includeRust {rustfmt.enable = true;}
      // optionalAttrs cfg.includeLeptos {leptosfmt.enable = true;}
      // optionalAttrs cfg.includeDeno {deno.enable = true;}
      // optionalAttrs cfg.includePrettier {
        prettier = {
          enable = true;
          package = pkgs.prettierd;
        };
      };

    settings = {
      excludes = ["node_modules" ".git" "target" "dist"];
      formatter =
        {}
        // optionalAttrs
        (programs.deno.enabe && programs.yamlfmt.enabe)
        {deno.excludes = ["*.yaml" "*.yml"];}
        // sqlFormatterSettings;
    };

    eval = treefmt.lib.evalModule pkgs {
      inherit projectRootFile programs settings;
    };
    build = eval.config.build;
    formatter = build.wrapper;
    packages = build.programs // {treefmt = formatter;};
    binaries = mkBins packages;
    variables = {};
  in {
    inherit
      binaries
      build
      cfg
      eval
      formatter
      packages
      programs
      projectRootFile
      settings
      variables
      ;
    inherit (build) check;
  };
in {inherit mkChecker mkFormatter mkTreefmt;}
