{
  pkgs,
  lix,
  lib,
  ...
}: let
  inherit (pkgs) curl docker gum jq writeScriptBin writeShellApplication;
  inherit (lix.filesystem.access) readFile;
  inherit (lix.strings.transformation) concat;
  inherit (lib) target tag set;

  env' = set "COMPOSE_FILE" (toString ./compose.yaml);

  entries = [
    {
      name = "up";
      description = "Start the ${target} service";
      runtimeInputs = [docker gum];
      script = ./up.sh;
    }
    {
      name = "down";
      description = "Stop the ${target} service";
      runtimeInputs = [docker];
      script = ./down.sh;
    }
    {
      name = "logs";
      description = "Follow ${target} container logs";
      runtimeInputs = [docker];
      script = ./logs.sh;
    }
    {
      name = "status";
      description = "Check ${target} API health";
      runtimeInputs = [curl gum];
      script = ./status.sh;
    }
    {
      name = "verify";
      description = "Validate the ${target} OpenAPI document";
      runtimeInputs = [curl jq];
      script = ./verify.sh;
    }
    {
      name = "bank-create";
      description = "Create a ${target} memory bank";
      runtimeInputs = [docker];
      script = ./bank-create.sh;
    }
    {
      name = "bank-list";
      description = "List ${target} memory banks";
      runtimeInputs = [docker];
      script = ./bank-list.sh;
    }
  ];

  scripts = map (entry:
    writeShellApplication {
      name = tag entry.name;
      inherit (entry) runtimeInputs;
      text = readFile entry.script;
    })
  entries;

  helpEntries =
    map (entry: {
      command = tag entry.name;
      inherit (entry) description;
    })
    entries;

  showHelp = writeScriptBin (tag "help") ''
    #!/bin/sh
    set -eu
    printf 'See: %s\n' "${
      concat ", " (map (entry: tag entry.name) entries)
    }"
  '';
in {
  env = env';
  packages = scripts ++ [showHelp];
  helpEntries =
    helpEntries
    ++ [
      {
        command = tag "help";
        description = "Show this help";
      }
    ];
}
