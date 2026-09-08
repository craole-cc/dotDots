{
  pkgs,
  lix,
  lib,
  cfg,
  paths,
  ...
}: let
  inherit
    (pkgs)
    cacert
    coreutils
    curl
    docker
    gum
    jq
    podman
    podman-compose
    python3
    tmux
    uv
    writeShellApplication
    writeText
    ;
  inherit (lix.filesystem.access) readFile;
  inherit (lib) target tag set;

  runtime = cfg.hindsight.runtime or "podman";
  version = cfg.hindsight.version or "0.9.2";

  nativeState = {
    data = "${paths.xdg.data.local}/${cfg.directory}/${target}/${cfg.instance}";
    cache = "${paths.xdg.cache.local}/${cfg.directory}/${target}/${cfg.instance}";
    session = "${target}-${cfg.instance}";
  };

  nativeRuntime = writeShellApplication {
    name = "${target}-native";
    runtimeInputs = [cacert coreutils python3 uv];
    text = ''
      : "''${HINDSIGHT_DATA_DIR:?HINDSIGHT_DATA_DIR not set}"
      : "''${HINDSIGHT_CACHE_DIR:?HINDSIGHT_CACHE_DIR not set}"
      : "''${HINDSIGHT_BIND_ADDRESS:?HINDSIGHT_BIND_ADDRESS not set}"
      : "''${HINDSIGHT_API_PORT:?HINDSIGHT_API_PORT not set}"

      mkdir -p "''${HINDSIGHT_DATA_DIR}" "''${HINDSIGHT_CACHE_DIR}"

      export HOME="''${HINDSIGHT_DATA_DIR}"
      export XDG_CACHE_HOME="''${HINDSIGHT_CACHE_DIR}"
      export UV_CACHE_DIR="''${HINDSIGHT_CACHE_DIR}/uv"
      export UV_PYTHON_DOWNLOADS=never
      export HF_HOME="''${HINDSIGHT_CACHE_DIR}/huggingface"
      export SSL_CERT_FILE="${cacert}/etc/ssl/certs/ca-bundle.crt"

      exec ${uv}/bin/uvx \
        --python ${python3}/bin/python \
        --from "hindsight-api==${version}" \
        hindsight-api \
        --host "''${HINDSIGHT_BIND_ADDRESS}" \
        --port "''${HINDSIGHT_API_PORT}" \
        "$@"
    '';
  };

  nativeRuntimeBin = "${nativeRuntime}/bin/${target}-native";

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

  containerRuntimeBin =
    if runtime == "podman"
    then podmanRuntimeBin
    else if runtime == "docker"
    then "${docker}/bin/docker"
    else null;

  runtimeInputs =
    if runtime == "native"
    then [nativeRuntime tmux uv python3 cacert]
    else if runtime == "podman"
    then [podman podman-compose podmanRuntime podmanCompose]
    else if runtime == "docker"
    then [docker]
    else throw "Unsupported Hindsight runtime '${runtime}'";

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
    set "RUNTIME_KIND" runtime
    // (
      if runtime == "native"
      then
        set "DATA_DIR" nativeState.data
        // set "CACHE_DIR" nativeState.cache
        // set "SESSION" nativeState.session
        // set "NATIVE_RUNTIME" nativeRuntimeBin
      else
        set "COMPOSE_FILE" compose
        // set "CONTAINER_RUNTIME" containerRuntimeBin
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
        )
    );

  entries = [
    {
      name = "up";
      description = "Start the ${target} service";
      runtimeInputs = [coreutils gum] ++ runtimeInputs;
      script = ./up.sh;
    }
    {
      name = "down";
      description = "Stop the ${target} service";
      runtimeInputs = [coreutils] ++ runtimeInputs;
      script = ./down.sh;
    }
    {
      name = "logs";
      description = "Follow ${target} service logs";
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
      description = "Report ${target} storage usage";
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
