{lib, ...}: let
  inherit (lib.attrsets) optionalAttrs;

  mkWeb = set:
    optionalAttrs (set != null) (
      {}
      // optionalAttrs (set.includeDeno or false) {
        deno = {
          source = ./deno.jsonc;
          target = "deno.jsonc";
        };
      }
      // optionalAttrs (set.includePrettier or false) {
        prettier = {
          source = ./prettierrc;
          target = [".prettierrc" "prettier.config.json"];
        };
      }
      // optionalAttrs (set.includeTrunk or false) {
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
in {inherit mkWeb;}
