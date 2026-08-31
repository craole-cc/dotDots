{lib, ...}:
lib.assembly.importLibs {
  inherit lib;
  path = ./.;
  priority = [
    "base"
    "editor"
    "rust"
    "web"
    "deploy.nix"
  ];
  ignore = [
    "ai.nix"
    "rust.nix"
  ];
}
