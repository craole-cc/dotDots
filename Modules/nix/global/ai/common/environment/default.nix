args: let
  LOCALHOST = "http://127.0.0.1";
  AUTO_START = 0;
  STARTUP_TIMEOUT = 15;
in {
  description = "AI Assistance";
  env = {
    inherit
      LOCALHOST
      AUTO_START
      STARTUP_TIMEOUT
      ;
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
}
