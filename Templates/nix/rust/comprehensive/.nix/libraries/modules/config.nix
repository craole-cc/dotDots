{lib}: let
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.modules) mkModules;
  inherit (lib.packages) mkChecker mkPkgs;
  inherit
    (lib.shells)
    mkVariantShells
    mkShells
    mkVariants
    normalizeVariant
    ;
  # inherit (lib.templates) deployTemplates;
in {
  mkConfig = {
    inputs,
    self,
    pkgs ? mkPkgs {inherit inputs;},
    configuration ? null,
    config ? {},
    extraPackages ? [],
    extraEnv ? {},
    extraShellHook ? "",
    variantName ? "default",
  }: let
    variants = let
      raw = mkVariants config;
      final = mapAttrs (_: normalizeVariant) raw;
    in {inherit raw final;};

    variant =
      if configuration != null
      then configuration
      else variants.final.${variantName} or (throw "mkConfig: unknown variantName '${variantName}'");

    modules = mkModules {inherit inputs pkgs variant;};
    # templates = deployTemplates {inherit pkgs variant;};
  in
    modules
    // {
      checks = mkChecker {inherit inputs self variant;};
      devShells = mkShells {
        inherit inputs;
        shells = mkVariantShells {
          inherit
            inputs
            pkgs
            variants
            extraPackages
            extraEnv
            extraShellHook
            ;
        };
      };
    };
}
