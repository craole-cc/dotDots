{lib, ...}:
lib.assembly.importLibs {
  inherit lib;
  path = ./.;
  scope = acc: lib // {shells = lib.shells // {web = acc;};};
  priority = ["tools.nix" "deploy.nix"];
}
