{lib, ...}: let
  inherit (lib.attrsets) optionalAttrs;

  mkWeb = set:
    optionalAttrs set.enable (
      {}
      // optionalAttrs set.includeDeno {
        deno = {
          source = ./deno.jsonc;
          target = "deno.jsonc";
        };
      }
      // optionalAttrs set.includePrettier {
        prettier = {
          source = ./prettierrc;
          target = [
            ".prettierrc"
            "prettier.config.json"
          ];
        };
      }
      // optionalAttrs set.includeTrunk {
        trunk = {
          source = ./trunk.toml;
          target = [
            ".trunk.toml"
            "Trunk.toml"
            ".trunk.yaml"
            "Trunk.yaml"
            ".trunk.json"
            "Trunk.json"
          ];
        };
      }
    );
in {
  inherit mkWeb;
}
