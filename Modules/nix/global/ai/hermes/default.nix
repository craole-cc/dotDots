{dots, ...}: let
  hermes = import ./environment {};
  package = import ./package.nix {
    inherit dots;
    inherit (hermes) description env;
  };

  shellHook = ''
    if [ -t 1 ]; then
      case "''${AUTO_START:-1}" in
        1) start --no-confirm || true ;;
        *) start || true ;;
      esac
      show-help
    fi
  '';
in {
  inherit (hermes) description env;
  inherit shellHook;
  packages = package.exports;
}
