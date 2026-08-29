{
  tools,
  print,
  env,
  ...
}: let
  inherit (tools) names commands versions origins descriptions;
in {
  shellHook = ''
    # Flake evaluation is pure by default, so package environment values may
    # have been derived without the invoking account's HOME. Resolve stateful
    # Hermes paths only when the shell actually starts.
    export HERMES_HOME="$HOME/.hermes"
    export HERMES_GATEWAY_CFG="$HERMES_HOME/gateway.json"

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

      case "${toString env.AUTO_START}" in
        1) start --no-confirm || true ;;
        *) start || true ;;
      esac
    fi
  '';
}
