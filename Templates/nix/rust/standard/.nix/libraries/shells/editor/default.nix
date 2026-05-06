{lib}:
lib.assembly.importLibs {
  inherit lib;
  path = ./.;
  scope = acc: lib // {shells = lib.shells // {editor = acc;};};
  priority = ["deploy.nix"];
}
