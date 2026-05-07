{lib}:
lib.assembly.importLibs {
  inherit lib;
  path = ./.;
  scope = acc: lib // {shells = lib.shells // {editor = acc;};};
  priority = [
    "tools.nix"
    "deploy.nix"
  ];
}
