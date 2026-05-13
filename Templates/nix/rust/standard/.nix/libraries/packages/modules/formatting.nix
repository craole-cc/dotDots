{lib}: let
  inherit
    (lib.attrsets)
    filterAttrs
    mapAttrs
    optionalAttrs
    recursiveUpdate
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

  mkTreefmt = {
    inputs,
    pkgs,
    variant,
    extraConfig ? {},
    projectRootFile ? "flake.nix",
  }: let
    system = getSystemOrDefault {inherit pkgs;};
    inherit (resolvePackages {inherit inputs;}) treefmt;

    cfg =
      variant.formatter or {
        enable = false;
        kind = "workflow";
        name = "formatter";
        includeDeno = false;
        includePrettier = false;
        includeRustfmt = false;
        includeLeptosfmt = false;
        sqlFormatters = {};
      };

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
      // (
        optionalAttrs
        cfg.includeRustfmt
        {rustfmt.enable = true;}
      )
      // (
        optionalAttrs
        cfg.includeLeptosfmt
        {leptosfmt.enable = true;}
      )
      // (
        optionalAttrs
        (cfg.includeDeno && for.allBut "riscv64-linux")
        {deno.enable = true;}
      )
      // (
        optionalAttrs
        cfg.includePrettier
        {
          prettier = {
            enable = true;
            package = pkgs.prettierd;
            settings.editorconfig = true;
          };
        }
      );

    settings = {
      excludes = ["node_modules" ".git" "target" "dist"];
      formatter =
        {}
        // (
          optionalAttrs
          (programs ? deno && programs ? yamlfmt)
          {deno.excludes = ["*.yaml" "*.yml"];}
        )
        // sqlFormatterSettings;
    };

    config =
      recursiveUpdate
      {inherit projectRootFile programs settings;}
      extraConfig;

    eval = treefmt.lib.evalModule pkgs config;
    build = eval.config.build;
    formatter = build.wrapper;
    packages = build.programs;
    binaries = mkBins packages;
    variables = {};
  in {
    inherit
      binaries
      build
      cfg
      config
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

  mkFormatter = {
    inputs,
    pkgs,
    variant,
    extraConfig ? {},
  }: let
    cfg =
      variant.formatter or {
        enable = false;
        kind = "workflow";
        name = "formatter";
      };
    fmt = mkTreefmt {inherit inputs pkgs variant extraConfig;};
  in {
    inherit (cfg) enable kind name;
    inherit
      (fmt)
      binaries
      formatter
      packages
      variables
      ;
  };

  mkChecker = {
    inputs,
    self,
    variant,
    extraConfig ? {},
  }:
    perSystem {
      inherit inputs;
      fn = pkgs: {
        formatting =
          (mkTreefmt {inherit inputs pkgs variant extraConfig;}).check self;
      };
    };
in {inherit mkChecker mkFormatter mkTreefmt;}
