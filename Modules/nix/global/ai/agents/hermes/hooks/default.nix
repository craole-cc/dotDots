{
  tools,
  print,
  env,
  ...
}: let
  inherit (tools) names commands versions origins descriptions;
in {
  shellHook = ''
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

    if [ -t 1 ]; then
      case "${toString env.AUTO_START}" in
        1) start --no-confirm || true ;;
        *) start || true ;;
      esac
    fi
  '';
}
