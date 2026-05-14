{lib, ...}: let
  inherit (lib.attrsets) optionalAttrs recursiveAttrs;
  inherit (lib.lists) elem toList;
  inherit
    (lib.packages)
    defineSystems
    getSystemOrDefault
    mkBins
    perSystem
    resolvePackages
    mkPkg
    ;

  mkFormatter = {
    inputs,
    pkgs,
    variant ? {},
    projectRootFile ? null,
  }: let
    system = getSystemOrDefault {inherit pkgs;};
    result = mkTreefmt {
      inherit
        inputs
        pkgs
        projectRootFile
        variant
        ;
    };
  in
    result
    // {
      formatter = {${system} = result.formatter;};
    };

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
            inherit
              inputs
              pkgs
              projectRootFile
              self
              variant
              ;
          }).check
          self;
      };
    };

  mkTreefmt = {
    inputs,
    pkgs,
    variant ? {},
    projectRootFile ? "flake.nix",
  }: let
    system = getSystemOrDefault {inherit pkgs;};
    inherit (resolvePackages {inherit inputs;}) treefmt;

    for = {
      allBut = systems: !(elem system (toList systems));
      all = {systems ? defineSystems}:
        elem system (toList systems);
    };

    cfg = let
      rust = variant.rust or {};
      web = variant.web or {};
      db = variant.db or {};

      set1 = {
        enable = false;
        kind = "workflow";
        name = "formatter";
        includeAlejandra = false;
        includeNixfmt = false;
        includeShfmt = false;
        includeShellcheck = false;
        includeStatix = false;
        includeDeno = false;
        includePrettier = false;
        includeRustfmt = false;
        includeLeptosfmt = false;
        includeSqlfmt = false;
        includeSqruff = false;
        includeXmllint = false;
      };
      set2 = variant.fmt or {};
      set3 = recursiveAttrs {inherit set1 set2;};
      set4 = {
        # includeNixfmt = set3.includeNixfmt && !set3.includeAlejandra;\
        includeNixfmt = set3.includeNixfmt && !set3.includeAlejandra;
        includeRustfmt = set3.includeRustfmt || ((rust.enable or false) && (rust.includeFmt or false));
        includeLeptosfmt =
          set3.includeLeptosfmt && (rust.enable or false) && (rust.includeFmt or false) && (rust.includeLeptos or false);
        includeDeno = set3.includeDeno && for.allBut "riscv64-linux";
        includePrettier = set3.includePrettier && (web.enable or false);
        includeXmllint = set3.includeXmllint || (web.enable or false);
        includeSqlfmt = set3.includeSqlfmt || ((db.enable or false) && !set3.includeSqruff);
        includeSqruff = set3.includeSqruff || ((db.enable or false) && !set3.includeSqlfmt);
        includeSqlite = (db.enable or false) && (db.includeSqlite or false);
        includePostgres = (db.enable or false) && (db.includePostgres or false);
        includeMysql = (db.enable or false) && (db.includeMysql or false);
        includeMariaDB = (db.enable or false) && (db.includeMariaDB or false);
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

    programs = with configuration;
      {
        actionlint.enable = true;
        taplo.enable = true;
        yamlfmt.enable = true;
      }
      // optionalAttrs includeAlejandra {alejandra.enable = true;}
      // optionalAttrs includeNixfmt {
        nixfmt = {
          enable = true;
          strict = true;
          width = 120;
          indent = 2;
        };
      }
      // optionalAttrs includeStatix {statix.enable = true;}
      // optionalAttrs includeShfmt {
        shfmt = {
          enable = true;
          useEditorConfig = true;
        };
      }
      // optionalAttrs includeShellcheck {
        shellcheck = {
          enable = true;
          external-sources = true;
          severity = "error";
          extra-checks = ["all"];
        };
      }
      // optionalAttrs includeRustfmt {rustfmt.enable = true;}
      // optionalAttrs includeLeptosfmt {leptosfmt.enable = true;}
      // optionalAttrs includeDeno {deno.enable = true;}
      // optionalAttrs includePrettier {
        prettier = {
          enable = true;
          package = pkgs.prettierd;
        };
      }
      // optionalAttrs includeXmllint {xmllint.enable = true;}
      // optionalAttrs includeSqlfmt {
        sql-formatter = {
          enable = true;
          dialect =
            if configuration.includeSqlite
            then "sqlite"
            else if configuration.includePostgres
            then "postgresql"
            else if configuration.includeMysql
            then "mysql"
            else if configuration.includeMariaDB
            then "mariadb"
            else null;
        };
      }
      // optionalAttrs includeSqruff {sqruff.enable = true;};

    settings = {
      excludes = [
        "node_modules"
        ".git"
        "target"
        "dist"
      ];
      formatter =
        {}
        // optionalAttrs ((programs ? deno) && programs.deno.enable && (programs ? yamlfmt) && programs.yamlfmt.enable) {
          deno.excludes = [
            "*.yaml"
            "*.yml"
          ];
        };
    };

    eval = treefmt.lib.evalModule pkgs {inherit projectRootFile programs settings;};
    build = eval.config.build;

    packages = let
      common = build.programs;
      custom = {
        treefmt = mkPkg {
          inherit pkgs;
          name = "treefmt";
          script = ''
            root=$(pwd)
            while [ ! -f "$root/flake.nix" ] && [ "$root" != "/" ]; do
              root=$(dirname "$root")
            done
            if [ ! -f "$root/flake.nix" ]; then
              printf 'treefmt: could not find project root (no flake.nix found)\n' >&2
              exit 1
            fi
            exec ${build.wrapper}/bin/treefmt --tree-root "$root" "$@"
          '';
        };
      };
      all = common // custom;
    in {
      inherit common custom all;
    };

    binaries = let
      common = mkBins packages.common;
      custom = mkBins packages.custom;
      all = common // custom;
    in {
      inherit all common custom;
    };

    variables = {};
  in {
    formatter = packages.all.treefmt;
    inherit
      binaries
      build
      cfg
      configuration
      eval
      packages
      programs
      projectRootFile
      settings
      variables
      ;
    inherit (build) check;
  };
in {
  inherit mkChecker mkFormatter mkTreefmt;
}
