{lib, ...}: let
  inherit (lib.packages) mkPkgs;
  inherit (lib.shells) setSource;
in {
  templates = {
    deno = {
      source = setSource ["web" "deno.jsonc"];
      target = "deno.jsonc";
    };
    prettier = {
      source = setSource ["web" "prettierrc"];
      target = [".prettierrc" "prettier.config.json"];
    };
    trunk = {
      source = setSource ["web" "trunk.toml"];
      target = [
        ".trunk.toml"
        "Trunk.toml"
        ".trunk.yaml"
        "Trunk.yaml"
        ".trunk.json"
        "Trunk.json"
      ];
    };
  };
}
