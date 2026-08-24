{
  pkgs,
  lix,
  print,
  env,
  ...
} @ args: let
  inherit (lix.attrsets.access) attrNames;
  inherit (env) name;

  descriptions = {
    "${name}-up" = "Start the ${name} service";
    "${name}-down" = "Stop the ${name} service";
    "${name}-logs" = "Follow ${name} container logs";
    "${name}-status" = "Check ${name} API health";
    "${name}-verify" = "Validate the ${name} OpenAPI document";
    "${name}-bank-create" = "Create a ${name} memory bank";
    "${name}-bank-list" = "List ${name} memory banks";
    "${name}-help" = "Show this help";
  };

  commandNames = attrNames descriptions;

  helpTable = ''
    ${print.title "Hindsight"}
    ${print.table {
      columns = ["Command" "Description"];
      rows = map (cmd: [cmd (descriptions.${cmd} or "?")]) commandNames;
    }}
  '';

  scripts = import ./scripts (args // {inherit descriptions helpTable;});
in {inherit descriptions helpTable scripts;}
