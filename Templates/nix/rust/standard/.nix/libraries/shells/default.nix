{lib, ...}:
lib.assembly.importLibs {
  inherit lib;
  path = ./.;
  priority = [
    "scripts.nix"
    "tools.nix"
    "build.nix"
    "meta.nix"
    "ai"
    "rust"
    "editor"
    "deploy.nix"
    "config.nix"
  ];
}
