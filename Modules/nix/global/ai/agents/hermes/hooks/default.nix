{
  names,
  print,
  commands,
  versions,
  origins,
  env,
  ...
} @ args: {
  packages = import ./scripts.nix args;
  shellHook = ''
    ${print.title "Hermes"}
    ${print.subtitle "Surfaces"}
    ${print.table {
      columns = ["name" "version" "source"];
      rows =
        map (name: [
          (commands.${name} or name)
          (versions.${name} or "?")
          (origins.${name} or "?")
        ])
        names;
    }}

    if [ -t 1 ]; then
      case "${toString env.AUTO_START}" in
        1) start --no-confirm || true ;;
        *) start || true ;;
      esac
      show-help
    fi
  '';
}
