{
  pkgs,
  lix,
  lib,
  cfg,
  paths,
  ...
}: let
  inherit (pkgs) coreutils curl docker gum jq podman podman-compose writeShellApplication writeText;
  inherit (lix.filesystem.access) readFile;
  inherit (lib) target tag set;

  runtime = cfg.hindsight.runtime or "podman";

  podmanState = let
    data = "${paths.xdg.data.local}/${cfg.directory}/containers/${target}/${cfg.instance}";
    run = "${paths.xdg.runtime.local}/${cfg.directory}/containers/${target}/${cfg.instance}";
  in {
    root = "${data}/storage";
    runroot = "${run}/run";
    tmpdir = "${run}/tmp";
  };

  podmanRuntime = writeShellApplication {
    name = "${target}-podman";
    runtimeInputs = [coreutils podman];
    text = ''
      : "''${HINDSIGHT_PODMAN_ROOT:?HINDSIGHT_PODMAN_ROOT not set}"
      : "''${HINDSIGHT_PODMAN_RUNROOT:?HINDSIGHT_PODMAN_RUNROOT not set}"
      : "''${HINDSIGHT_PODMAN_TMPDIR:?HINDSIGHT_PODMAN_TMPDIR not set}"

      mkdir -p \
        "''${HINDSIGHT_PODMAN_ROOT}" \
        "''${HINDSIGHT_PODMAN_RUNROOT}" \
        "''${HINDSIGHT_PODMAN_TMPDIR}"

      exec ${podman}/bin/podman \
        --root "''${HINDSIGHT_PODMAN_ROOT}" \
        --runroot "''${HINDSIGHT_PODMAN_RUNROOT}" \
        --tmpdir "''${HINDSIGHT_PODMAN_TMPDIR}" \
        "$@"
    '';
  };

  podmanRuntimeBin = "${podmanRuntime}/bin/${target}-podman";

  podmanCompose = writeShellApplication {
    name = "${target}-podman-compose";
    runtimeInputs = [podman-compose];
    text = ''
      exec ${podman-compose}/bin/podman-compose \
        --podman-path ${podmanRuntimeBin} \
        "$@"
    '';
  };

  runtimeBin =
    if runtime == "podman"
    then podmanRuntimeBin
    else if runtime == "docker"
    then "${docker}/bin/docker"
    else throw "Unsupported Hindsight container runtime '${runtime}'";

  runtimeInputs =
    if runtime == "podman"
    then [podman podman-compose podmanRuntime podmanCompose]
    else [docker];

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
    // set "CONTAINER_RUNTIME" runtimeBin
    // set "CONTAINER_RUNTIME_KIND" runtime
    // (
      if runtime == "podman"
      then
        set "PODMAN_ROOT" podmanState.root
        // set "PODMAN_RUNROOT" podmanState.runroot
        // set "PODMAN_TMPDIR" podmanState.tmpdir
        // {
          CONTAINERS_POLICY_JSON = policy;
          PODMAN_COMPOSE_PROVIDER = "${podmanCompose}/bin/${target}-podman-compose";
          PODMAN_COMPOSE_WARNING_LOGS = "false";
        }
      else {}
    );

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
