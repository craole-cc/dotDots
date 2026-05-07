{lib}: let
  inherit (lib.attrsets) mapAttrs recursiveUpdate;
  inherit (lib.lists) elem optionals toList;
  inherit (lib.packages) defineSystems resolvePackages perSystem;

  mkTreefmt = {
    self,
    inputs,
    config ? {},
    includeWeb ? false,
    includeExtras ? false,
    includeDatabase ? false,
    includeRust ? false,
  }: let
    inherit (resolvePackages {inherit inputs;}) treefmt;

    evaluated = perSystem {
      inherit inputs;
      fn = pkgs: let
        module = treefmt.lib.evalModule pkgs (
          mkTreefmtConfig {
            inherit
              pkgs
              config
              includeWeb
              includeRust
              includeDatabase
              ;
          }
        );
        inherit (module.config.build) check wrapper programs;
        formatting = check self;
      in {inherit formatting programs wrapper;};
    };
  in {
    formatter = mapAttrs (_: v: v.wrapper) evaluated;
    checks = mapAttrs (_: v: {inherit (v) formatting;}) evaluated;
    packages = mapAttrs (_: v: v.programs) evaluated;
  };

  mkTreefmtConfig = {
    pkgs,
    config,
    includeWeb ? false,
    includeRust ? false,
    includeDatabase ? false,
  }: let
    inherit (pkgs.stdenv.hostPlatform) system;
    for = {
      allBut = systems: !(elem system (toList systems));
      all = {systems ? defineSystems}: (elem system (toList systems));
    };
  in
    recursiveUpdate {
      projectRootFile = "flake.nix";

      programs = {
        #~@ Common
        actionlint.enable = true;
        alejandra.enable = for.all {};
        shellcheck.enable = true;
        shfmt.enable = true;
        statix.enable = true;
        taplo.enable = true;
        yamlfmt.enable = true;

        #~@ Rust
        leptosfmt.enable = includeRust && includeWeb;
        rustfmt.enable = includeRust;

        #~@ Web
        deno.enable = includeWeb && for.allBut "riscv64-linux";

        #~@ Database
        sql-formatter = {
          enable = includeDatabase;
          dialect = "sqlite";
        };
      };

      settings = {
        excludes = ["node_modules" ".git" "target" "dist"];
        formatter = {
          deno.excludes = optionals includeWeb ["*.yaml" "*.yml"];
        };
      };
    }
    config;
in {inherit mkTreefmt mkTreefmtConfig;}
