{lib, ...}:
lib.assembly.importLibs {
  inherit lib;
  path = ./.;
  priority = [
    "core.nix"
    "data.nix"
    "scripts.nix"
    "formatting.nix"
    "meta.nix"
    "tools.nix"
    "config.nix"
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
