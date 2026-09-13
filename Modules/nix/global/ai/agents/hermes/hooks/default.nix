{
  tools,
  print,
  cfg,
  paths,
  ...
}: let
  inherit (tools) names commands versions origins descriptions;
  hermesSecrets = "${paths.home.private.local}/${cfg.hermes.secrets}";
in {
  shellHook = ''
    export HERMES_HOME="''${HERMES_HOME:-$HOME/.hermes}"
    export HERMES_GATEWAY_CFG="''${HERMES_GATEWAY_CFG:-$HERMES_HOME/gateway.json}"
    export HERMES_SECRETS_FILE="''${HERMES_SECRETS_FILE:-${hermesSecrets}}"

    if [ -r "$HERMES_SECRETS_FILE" ]; then
      if [ -L "$HERMES_SECRETS_FILE" ] || [ ! -f "$HERMES_SECRETS_FILE" ]; then
        printf '%s\n' "Refusing non-regular Hermes secrets file: $HERMES_SECRETS_FILE" >&2
        return 1
      fi

      owner="$(stat -c '%u' "$HERMES_SECRETS_FILE")"
      mode="$(stat -c '%a' "$HERMES_SECRETS_FILE")"
      if [ "$owner" != "$(id -u)" ] || [ $((0$mode & 077)) -ne 0 ]; then
        printf '%s\n' "Refusing Hermes secrets file not owned and private to this user: $HERMES_SECRETS_FILE" >&2
        return 1
      fi
      unset owner mode

      set -a
      # shellcheck disable=SC1090
      . "$HERMES_SECRETS_FILE"
      set +a
    fi

    unalias hermes 2>/dev/null || true

    if [ -t 1 ]; then
      ${print.title "Hermes Agent"}
      ${print.table {
      columns = ["Name" "Version" "Source" "Description"];
      rows =
        map (name: [
          (commands.${name} or name)
          (versions.${name} or "?")
          (origins.${name} or "?")
          (descriptions.${name} or "?")
        ])
        names;
    }}

      case "''${AUTO_START:-0}" in
        1) start --no-confirm || true ;;
      esac
    fi
  '';
}
