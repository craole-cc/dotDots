{lib, ...}: let
  inherit (lib.attrsets) optionalAttrs;

  mkBase = set:
    optionalAttrs (set != null) (
      {
        envrc = {
          source = ./envrc;
          target = ".envrc";
        };

        gitignore = {
          source = ./gitignore;
          target = ".gitignore";
        };
      }
      // optionalAttrs (set.includeMise or false) {
        mise = {
          source = ./mise.toml;
          target = [".mise.toml" "mise.toml"];
        };
      }
    );
in {
  inherit mkBase;
}
