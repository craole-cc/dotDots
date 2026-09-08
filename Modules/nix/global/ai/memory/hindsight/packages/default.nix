{
  pkgs,
  lix,
  lib,
  cfg,
  ...
}: let
  inherit (pkgs) coreutils curl docker gum jq podman podman-compose writeShellApplication writeText;
  inherit (lix.filesystem.access) readFile;
  inherit (lib) target tag set;

  runtime = cfg.hindsight.runtime or "podman";
  runtimeInputs =
    if runtime == "podman"
    then [podman podman-compose]
    else if runtime == "docker"
    then [docker]
    else throw "Unsupported Hindsight container runtime '${runtime}'";

  compose = writeText "${target}-compose.yaml" (readFile ./compose.yaml);
  policy = writeText "${target}-containers-policy.json" ''
    {
      "default": [
        {
          "type": "insecureAcceptAnything"
        }
      ]
    }
  '';

  env' =
    set "COMPOSE_FILE" compose
    // set "CONTAINER_RUNTIME" runtime
    // {
      CONTAINERS_POLICY_JSON = policy;
      PODMAN_COMPOSE_PROVIDER = "${podman-compose}/bin/podman-compose";
    };

  entries = [
    {
      name = "up";
      description = "Start the ${target} service";
      runtimeInputs = [coreutils] ++ runtimeInputs ++ [gum];
      script = ./up.sh;
    }
    {
      name = "down";
      description = "Stop the ${target} service";
      inherit runtimeInputs;
      script = ./down.sh;
    }
    {
      name = "logs";
      description = "Follow ${target} container logs";
      inherit runtimeInputs;
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
      description = "Report ${target} container storage usage";
      runtimeInputs = [coreutils] ++ runtimeInputs;
      script = ./storage.sh;
    }
    {
      name = "bank-create";
      description = "Create a ${target} memory bank";
      runtimeInputs = [curl jq];
      script = ./bank-create.sh;
    }
    {
      name = "bank-list";
      description = "List ${target} memory banks";
      runtimeInputs = [curl jq];
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
  packages = runtimeInputs ++ scripts;
  inherit helpEntries;
}
