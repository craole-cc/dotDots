{lib, ...}: let
  inherit (lib.attrsets) mapAttrs recursiveUpdate;
  inherit (lib.lists) elem toList;
  inherit (lib.packages) defineSystems resolvePackages perSystem;

  mkTreefmt = {
    self,
    inputs,
    config ? {},
  }: let
    inherit (resolvePackages {inherit inputs;}) treefmt;

    evaluated = perSystem {
      inherit inputs;
      fn = pkgs: let
        module = treefmt.lib.evalModule pkgs (
          mkTreefmtConfig {inherit pkgs config;}
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
        actionlint.enable = true;
        alejandra.enable = for.all {};
        deno.enable = for.allBut "riscv64-linux";
        leptosfmt.enable = true;
        rustfmt.enable = true;
        shellcheck.enable = true;
        shfmt.enable = true;
        sql-formatter = {
          enable = true;
          dialect = "sqlite";
        };
        statix.enable = true;
        taplo.enable = true;
        yamlfmt.enable = true;
      };

      settings = {
        excludes = ["node_modules" ".git" "target" "dist"];
        formatter = {
          deno.excludes = ["*.yaml" "*.yml"];
        };
      };
    }
    config;
in {inherit mkTreefmt mkTreefmtConfig;}
