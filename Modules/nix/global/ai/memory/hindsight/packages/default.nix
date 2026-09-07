{
  pkgs,
  lix,
  lib,
  ...
}: let
  inherit (pkgs) coreutils curl docker gum jq writeShellApplication writeText;
  inherit (lix.filesystem.access) readFile;
  inherit (lib) target tag set;

  compose = writeText "${target}-compose.yaml" (readFile ./compose.yaml);
  env' = set "COMPOSE_FILE" compose;

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
      name = "storage";
      description = "Report ${target} Docker storage usage";
      runtimeInputs = [coreutils docker];
      script = ./storage.sh;
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
in {
  env = env';
  packages = [docker] ++ scripts;
  inherit helpEntries;
}
