{lib, ...}:
lib.assembly.importLibs {
  inherit lib;
  path = ./.;
  priority = [
    "scripts.nix"
    "build.nix"
    "meta.nix"
    "common"
    "web"
    "ai"
    "rust"
    "editor"
    "tools.nix"
    "deploy.nix"
    # "config.nix"
    "environment.nix"
  ];
}
