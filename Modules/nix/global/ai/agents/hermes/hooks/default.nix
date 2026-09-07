{
  tools,
  print,
  ...
}: let
  inherit (tools) names commands versions origins descriptions;
in {
  shellHook = ''
    export HERMES_HOME="''${HERMES_HOME:-$HOME/.hermes}"
    export HERMES_GATEWAY_CFG="''${HERMES_GATEWAY_CFG:-$HERMES_HOME/gateway.json}"

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
