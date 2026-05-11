{lib}: let
  inherit (lib.attrsets) mapAttrs optionalAttrs recursiveUpdate;
  inherit (lib.lists) elem toList;
  inherit (lib.packages) defineSystems resolvePackages perSystem;

  mkTreefmt = {
    pkgs,
    variant,
    extraConfig ? {},
  }: let
    inherit (pkgs.stdenv.hostPlatform) system;

    projectRootFile = "flake.nix";

    for = {
      allBut = systems: !(elem system (toList systems));
      all = {systems ? defineSystems}: elem system (toList systems);
    };

    cfg = {
      rust = variant.rust.enable;
      web = variant.web.enable;
      deno = variant.web.enable && variant.web.includeDeno;
      prettier = variant.web.enable && variant.web.includePrettier;
      leptos =
        (variant.rust.enable && variant.web.enable)
        || variant.rust.includeLeptos;
      database = variant.database.enable;
    };

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
      // optionalAttrs cfg.rust {
        rustfmt.enable = true;
      }
      // optionalAttrs cfg.leptos {
        leptosfmt.enable = true;
      }
      // optionalAttrs (cfg.deno && for.allBut "riscv64-linux") {
        deno.enable = true;
      }
      // optionalAttrs cfg.prettier {
        prettier = {
          enable = true;
          package = pkgs.prettierd;
          settings.editorconfig = true;
        };
      }
      // optionalAttrs cfg.database {
        sql-formatter = {
          enable = true;
          dialect = "sqlite";
        };
      };

    settings = {
      excludes = ["node_modules" ".git" "target" "dist"];
      formatter =
        {}
        // optionalAttrs (programs ? deno && programs ? yamlfmt) {
          deno.excludes = ["*.yaml" "*.yml"];
        };
    };
  in
    recursiveUpdate
    {inherit projectRootFile programs settings;}
    extraConfig;

  mkFormatting = {
    inputs,
    self,
  }: variant: let
    treefmt = perSystem {
      inherit inputs;
      fn = pkgs: let
        module =
          (resolvePackages {inherit inputs;}).treefmt.lib.evalModule pkgs
          (mkTreefmt {inherit pkgs variant;});
      in
        module.config.build;
    };
  in {
    formatter = mapAttrs (_: v: v.wrapper) treefmt;
    checks = mapAttrs (_: v: {formatting = v.check self;}) treefmt;
    packages = mapAttrs (_: v: v.programs) treefmt;
  };
in {
  inherit mkFormatting mkTreefmt;
}
