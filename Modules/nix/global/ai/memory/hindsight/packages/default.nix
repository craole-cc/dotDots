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
      : "''${HINDSIGHT_SECRETS_FILE:?HINDSIGHT_SECRETS_FILE not set}"
      : "''${HINDSIGHT_DATA_DIR:?HINDSIGHT_DATA_DIR not set}"
      : "''${HINDSIGHT_CACHE_DIR:?HINDSIGHT_CACHE_DIR not set}"
      : "''${HINDSIGHT_BIND_ADDRESS:?HINDSIGHT_BIND_ADDRESS not set}"
      : "''${HINDSIGHT_API_PORT:?HINDSIGHT_API_PORT not set}"

      if [ ! -r "''${HINDSIGHT_SECRETS_FILE}" ]; then
        printf '%s\n' "Hindsight secrets file is not readable: ''${HINDSIGHT_SECRETS_FILE}" >&2
        exit 1
      fi

      # shellcheck disable=SC1090
      . "''${HINDSIGHT_SECRETS_FILE}"

      case "''${HINDSIGHT_LLM_BACKEND:-openrouter}" in
      openrouter)
        key="''${OPENROUTER_API_KEY:-''${HINDSIGHT_OPENROUTER_API_KEY:-}}"
        : "''${key:?OPENROUTER_API_KEY is required in ''${HINDSIGHT_SECRETS_FILE}}"
        ;;
      groq)
        key="''${GROQ_API_KEY:-''${HINDSIGHT_GROQ_API_KEY:-}}"
        : "''${key:?GROQ_API_KEY is required in ''${HINDSIGHT_SECRETS_FILE}}"
        ;;
      *)
        printf '%s\n' "Unsupported Hindsight LLM backend: ''${HINDSIGHT_LLM_BACKEND}" >&2
        exit 1
        ;;
      esac

      mkdir -p "''${HINDSIGHT_DATA_DIR}" "''${HINDSIGHT_CACHE_DIR}"

      export HINDSIGHT_API_LLM_API_KEY="''${key}"
      export HINDSIGHT_API_LLM_PROVIDER="openai"
      export HINDSIGHT_API_LLM_BASE_URL="''${HINDSIGHT_LLM_BASE_URL}"
      export HINDSIGHT_API_LLM_MODEL="''${HINDSIGHT_LLM_MODEL}"
      export HINDSIGHT_API_RETAIN_LLM_MODEL="''${HINDSIGHT_LLM_MODEL}"
      export HINDSIGHT_API_CONSOLIDATION_LLM_MODEL="''${HINDSIGHT_LLM_MODEL}"
      export HINDSIGHT_API_REFLECT_LLM_MODEL="''${HINDSIGHT_REFLECT_LLM_MODEL}"
      export HINDSIGHT_API_DATABASE_URL="pg0"
      export HINDSIGHT_API_HOST="''${HINDSIGHT_BIND_ADDRESS}"
      export HINDSIGHT_API_PORT="''${HINDSIGHT_API_PORT}"

      # The top-level hindsight-api package pulls the `all` extra, including
      # PyTorch and multi-gigabyte CUDA wheels. Native shells do not need that
      # stack: use Hindsight's ONNX embeddings plus the pure RRF reranker.
      export HINDSIGHT_API_EMBEDDINGS_PROVIDER="onnx"
      export HINDSIGHT_API_EMBEDDINGS_ONNX_MODEL_ID="intfloat/multilingual-e5-small"
      export HINDSIGHT_API_EMBEDDINGS_ONNX_FILE="onnx/model.onnx"
      export HINDSIGHT_API_RERANKER_PROVIDER="rrf"
      unset key

      export HOME="''${HINDSIGHT_DATA_DIR}"
      export XDG_CACHE_HOME="''${HINDSIGHT_CACHE_DIR}"
      export UV_CACHE_DIR="''${HINDSIGHT_CACHE_DIR}/uv"
      export UV_PYTHON_DOWNLOADS=never
      export HF_HOME="''${HINDSIGHT_CACHE_DIR}/huggingface"
      export SSL_CERT_FILE="${cacert}/etc/ssl/certs/ca-bundle.crt"

      # uv/pg0 execute upstream ELF binaries outside the Nix store. Expose
      # their runtime sonames explicitly instead of depending on host-global
      # libraries. This covers Python wheels such as tokenizers/onnxruntime
      # plus pg0's bundled PostgreSQL runtime.
      export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib
        pkgs.zstd
        pkgs.lz4
        pkgs.openssl
        pkgs.krb5
        pkgs.zlib
        pkgs.xz
      ]}''${LD_LIBRARY_PATH:+:''${LD_LIBRARY_PATH}}"

      exec ${uv}/bin/uvx \
        --python ${python3}/bin/python \
        --from "hindsight-api-slim[local-onnx,embedded-db]==${version}" \
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
        set "SESSION" nativeState.session
        // set "NATIVE_RUNTIME" nativeRuntimeBin
      else
        set "COMPOSE_FILE" compose
        // set "CONTAINER_RUNTIME" containerRuntimeBin
        // (
          if runtime == "podman"
          then {
            CONTAINERS_POLICY_JSON = policy;
            PODMAN_COMPOSE_PROVIDER = "${podmanCompose}/bin/${target}-podman-compose";
            PODMAN_COMPOSE_WARNING_LOGS = "false";
          }
          else {}
        )
    );

  # Schema paths may intentionally contain runtime variables such as
  # ${HOME} or ${UID}. mkShell's `env` passes those strings literally, so
  # materialize path-valued runtime state in the shell hook where the shell
  # can expand them. The source of truth remains the schema-derived `paths`.
  runtimeHook =
    if runtime == "native"
    then ''
      export HINDSIGHT_DATA_DIR="${nativeState.data}"
      export HINDSIGHT_CACHE_DIR="${nativeState.cache}"
    ''
    else if runtime == "podman"
    then ''
      export HINDSIGHT_PODMAN_ROOT="${podmanState.root}"
      export HINDSIGHT_PODMAN_RUNROOT="${podmanState.runroot}"
      export HINDSIGHT_PODMAN_TMPDIR="${podmanState.tmpdir}"
    ''
    else "";

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
  shellHook = runtimeHook;
  inherit helpEntries;
}
