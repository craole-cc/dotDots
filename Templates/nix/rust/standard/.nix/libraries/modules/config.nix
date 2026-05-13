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
      variants.final.${
        variantName
      } or (
        throw "mkConfig: unknown variantName '${variantName}'"
      );

    modules = mkModules {inherit inputs pkgs variant;};
    # templates = deployTemplates {inherit pkgs variant;};
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
  in
    modules
    // {
      checks = mkChecker {inherit inputs self variant;};
      formatter = modules.modules.formatting.formatter or null;
      devShells = mkShells {inherit inputs shells;};
    };
}
