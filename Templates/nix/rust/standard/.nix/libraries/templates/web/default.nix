{
  deno = {
    source = ./. + "deno.jsonc";
    target = "deno.jsonc";
  };
  prettier = {
    source = ./. + "prettierrc";
    target = [".prettierrc" "prettier.config.json"];
  };
  trunk = {
    source = ./. + "trunk.toml";
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
