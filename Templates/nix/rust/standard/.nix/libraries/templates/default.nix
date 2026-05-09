{
  lib,
  paths,
  ...
}:
lib.assembly.importLibs {
  inherit lib paths;
  path = ./.;
  args = {inherit paths;};
  scope = acc: lib // {shells = lib.shells // {common = acc;};};
  priority = [
    "deploy.nix"

    "base.nix"
    "extra.nix"
    "web.nix"
    "ai.nix"

    "config.nix"
  ];
  ignore = ["ai.nix" "rust.nix"];
}
