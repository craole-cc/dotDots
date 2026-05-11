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

    programs = {
      actionlint.enable = true;
      alejandra.enable = for.all {};
      shellcheck.enable = true;
      shfmt.enable = true;
      statix.enable = true;
      taplo.enable = true;
      yamlfmt.enable = true;

      leptosfmt.enable = variant.rust.enable && variant.web.enable;
      rustfmt.enable = variant.rust.enable;

      deno.enable = variant.web.enable && for.allBut "riscv64-linux";

      sql-formatter = {
        inherit (variant.database) enable;
        dialect = "sqlite";
      };
    };

    settings = {
      excludes = ["node_modules" ".git" "target" "dist"];
      formatter =
        {}
        // optionalAttrs (programs.deno.enable && programs.yamlfmt.enable) {
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
    # checks = mapAttrs (_: v: v.check self) treefmt;
    checks = mapAttrs (_: v: {formatting = v.check self;}) treefmt;
    packages = mapAttrs (_: v: v.programs) treefmt;
  };
in {
  inherit mkFormatting mkTreefmt;
}
