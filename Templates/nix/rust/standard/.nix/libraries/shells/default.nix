{lib, ...}:
lib.assembly.importLibs {
  inherit lib;
  path = ./.;
  priority = [
    "scripts.nix"
    "build.nix"
    "formatter.nix"
    "meta.nix"
    "tools.nix"
    "deploy.nix"
    # "config.nix"
    "variants.nix"
    "environment.nix"
  ];
  ignore = [
    "common"
    "web"
    "ai"
    "rust"
    "editor"
    "config.nix"
  ];
}
