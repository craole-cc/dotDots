{ lib }:
let
  inherit (lib.attrsets) attrValues;
  inherit (lib.packages) getSystem;
  inherit (lib.shells) deployConfig mkTools;
  inherit (lib.shells) ai mergeNamespaces rust;

  combined = mergeNamespaces { inherit rust ai; };
  inherit (combined) mkSpec;
in
{
  mkSuite =
    { pkgs, fmt }:
    {
      shellArgs ? { },
      deployArgs ? { },
      extraPackages ? [ ],
      ...
    }:
    let
      tools = mkTools ({ inherit pkgs; } // shellArgs);
      spec = mkSpec ({ inherit pkgs; } // shellArgs);
      shell = spec.shell // {
        shellHook = "";
        packages =
          spec.shell.packages
          ++ (attrValues fmt.packages.${getSystem pkgs})
          ++ tools.packages
          ++ [
            deployConfig
            ({ inherit pkgs; } // deployArgs)
          ]
          ++ extraPackages;
      };
    in
    spec // { inherit shell; };
}
