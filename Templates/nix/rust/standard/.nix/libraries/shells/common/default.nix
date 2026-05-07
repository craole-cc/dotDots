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
  priority = ["base.nix" "extra.nix" "web.nix" "tools.nix"];
}
