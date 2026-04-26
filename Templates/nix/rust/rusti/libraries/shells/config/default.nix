{lib}:
lib.assembly.importAttrs {
  inherit lib;
  path = ./.;
  # scope = acc: lib // {shells = lib.shells // {rust = acc;};};
  # ignore = ["combined.nix" ];
}
