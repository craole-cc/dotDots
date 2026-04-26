{lib}:
lib.assembly.importLibs {
  inherit lib;
  path = ./.;
  priority = ["spec.nix"];
  scope = acc: lib // {shells = lib.shells // {ai = acc;};};
}
