{
  pkgs,
  print,
  env,
  ...
}: let
  inherit (pkgs) writeShellApplication;
  inherit (env) HERMES_HOME HERMES_ENV_SH;
in {
  start = writeShellApplication {
    name = "start";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      set -euo pipefail

      no_confirm=0
      for arg in "$@"; do
        case "$arg" in
          --no-confirm|-y) no_confirm=1 ;;
        esac
      done

      # shellcheck disable=SC1090
      [ -f "${HERMES_ENV_SH}" ] && . "${HERMES_ENV_SH}"

      mkdir -p "${HERMES_HOME}"

      if command -v hermes >/dev/null 2>&1; then
        if [ "$no_confirm" -eq 1 ]; then
          echo "Starting hermes gateway (no-confirm)..."
          hermes gateway start 2>/dev/null || hermes serve 2>/dev/null || true
        else
          echo "Hermes CLI is available. Run: hermes --help"
          echo "Gateway: hermes gateway start"
        fi
      else
        echo "hermes binary not on PATH" >&2
        exit 1
      fi
    '';
  };

  show-help = writeShellApplication {
    name = "show-help";
    text = ''
      set -euo pipefail

      ${print.title "Hermes shell"}
      ${print.subtitle "Commands"}
      cat <<'EOF'
        hermes              Agent CLI (official)
        hermes-desktop      Official desktop GUI
        hermes-one          Community desktop (Hermes One)
        hermes-hud          Status / memory TUI
        hermes-tui          Official terminal UI

        start [--no-confirm]   Bootstrap / start gateway
        show-help              This help
      EOF

      ${print.subtitle "Paths"}
      cat <<EOF
        HERMES_HOME=${HERMES_HOME}
      EOF
    '';
  };
}
