{lib}:
lib.assembly.importLibs {
  inherit lib;
  path = ./.;
  scope = acc: lib // {shells = lib.shells // {ai = acc;};};
}
