{ lib }:
let
  inherit (lib.attrsets) attrNames listToAttrs;
  inherit (lib.packages) mkFmt mkChecks;
  inherit (lib.lists) concatMap;
  inherit (lib.shells) mkShells;

  inherit (import ./suite.nix { inherit lib; }) mkSuite;
  inherit (import ./variants.nix { })
    baseArgs
    baseDeployArgs
    editorNames
    editorSuffixes
    ;

  mkSuites =
    {
      inputs,
      pkgs,
      self,
    }:
    let
      mkFmt' = mkFmt { inherit inputs self; };

      mkVariant =
        {
          shellArgs ? { },
          deployArgs ? { },
        }:
        let
          fmt = mkFmt' shellArgs;
        in
        mkSuite { inherit pkgs fmt; } { inherit shellArgs deployArgs; };

      baseNames = attrNames baseArgs;

      baseVariants = listToAttrs (
        map (name: {
          inherit name;
          value = mkVariant { shellArgs = baseArgs.${name}; };
        }) baseNames
      );

      editorVariants = listToAttrs (
        concatMap (
          baseName:
          map (editorName: {
            name = "${baseName}With${editorSuffixes.${editorName}}";
            value = mkVariant {
              shellArgs = baseArgs.${baseName} // {
                includeEditor = true;
              };
              deployArgs = baseDeployArgs.${baseName} // {
                withEditor = editorName;
              };
            };
          }) editorNames
        ) baseNames
      );

      namespaced = (lib.shells.mergeNamespaces { inherit (lib.shells) rust ai; }).mkSuite { inherit pkgs; };
    in
    {
      devShells = mkShells {
        inherit inputs;
        default = baseVariants.minimal;
        shells = namespaced // baseVariants // editorVariants;
      };
      checks = mkChecks {
        bases = baseArgs;
        mkFmt = mkFmt';
      };
      fmt = mkFmt' baseArgs.default;
    };
in
{
  inherit mkSuites;
  mkDevShells = mkSuites;
}
