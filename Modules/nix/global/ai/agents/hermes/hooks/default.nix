{
  lix,
  print,
  commands,
  versions,
  AUTO_START,
  ...
}: {
  shellHook = ''
    ${print.title "Hermes"}
    ${print.subtitle "Surfaces"}
    ${print.table {
      columns = ["name" "version" "source"];
      rows =
        map (name: [
          name
          (versions.${name} or "?")
          (toString (commands.${name} or "?"))
        ])
        commands;
    }}

    # existing behaviour
    if [ -t 1 ]; then
      case "${AUTO_START}" in
        1) start --no-confirm || true ;;
        *) start || true ;;
      esac
      show-help
    fi
  '';
}
