{lib}:
lib.assembly.importLibs {
  inherit lib;
  path = ./.;
  priority = ["config" "ai" "rust" "combined"];
}
