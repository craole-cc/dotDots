{lib}:
lib.assembly.importLibs {
  inherit lib;
  path = ./.;
  priority = [ "ai" "rust" "config" ];
}
