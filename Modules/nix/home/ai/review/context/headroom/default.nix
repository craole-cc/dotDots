{
  pkgs,
  cfg,
  paths,
  ...
}: let
  inherit (pkgs) coreutils curl gum lsof procps python313 tmux uv writeShellApplication;
  inherit (pkgs.lib) makeLibraryPath;

  h = cfg.headroom;
  inherit (h) bindAddress;
  port = toString h.port;
  dataDir = "${paths.xdg.data.local}/${cfg.directory}/${h.state}";
  configDir = "${paths.xdg.config.local}/${cfg.directory}/${h.state}";
  cacheDir = "${paths.xdg.cache.local}/${cfg.directory}/${h.state}";
  version = "0.37.0";
  runtimeLibraryPath = makeLibraryPath [pkgs.stdenv.cc.cc.lib];

  headroom = writeShellApplication {
    name = "headroom";
    runtimeInputs = [uv python313];
    text = ''
      export UV_CACHE_DIR="''${HEADROOM_UV_CACHE:-${cacheDir}/uv}"
      export LD_LIBRARY_PATH="${runtimeLibraryPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      mkdir -p "$UV_CACHE_DIR"
      exec uvx --python ${python313}/bin/python3.13 --from "headroom-ai[proxy,code]==${version}" headroom "$@"
    '';
  };

  start = writeShellApplication {
    name = "headroom-start";
    runtimeInputs = [headroom];
    text = ''
      export HEADROOM_HOST="''${HEADROOM_HOST:-${bindAddress}}"
      export HEADROOM_PORT="''${HEADROOM_PORT:-${port}}"
      # Keep our concise policy label for users, then map it to Headroom's
      # supported 0.37 settings: token savings plus AST-aware compression.
      export HEADROOM_SAVINGS_PROFILE="''${HEADROOM_SAVINGS_PROFILE:-coding}"
      export HEADROOM_MODE="''${HEADROOM_MODE:-token}"
      export HEADROOM_CODE_AWARE_ENABLED="''${HEADROOM_CODE_AWARE_ENABLED:-1}"
      # 9Router returns streaming OpenAI-compatible responses.  Headroom's
      # default CCR markers require a retrieval tool round-trip that those
      # clients cannot perform, so keep code-aware savings marker-free.
      export HEADROOM_LOSSLESS="''${HEADROOM_LOSSLESS:-1}"
      export HEADROOM_TELEMETRY="''${HEADROOM_TELEMETRY:-on}"
      export HEADROOM_PROVIDER_NAME="''${HEADROOM_PROVIDER_NAME:-9Router}"
      export HEADROOM_WORKSPACE_DIR="''${HEADROOM_WORKSPACE_DIR:-${dataDir}}"
      export HEADROOM_CONFIG_DIR="''${HEADROOM_CONFIG_DIR:-${configDir}}"
      mkdir -p "$HEADROOM_WORKSPACE_DIR" "$HEADROOM_CONFIG_DIR"

      if [ -n "''${OPENAI_TARGET_API_URL:-}" ]; then
        exec headroom proxy \
          --host "$HEADROOM_HOST" \
          --port "$HEADROOM_PORT" \
          --mode "$HEADROOM_MODE" \
          --code-aware \
          --lossless \
          --openai-api-url "$OPENAI_TARGET_API_URL" \
          --provider-name "$HEADROOM_PROVIDER_NAME"
      fi

      exec headroom proxy \
        --host "$HEADROOM_HOST" \
        --port "$HEADROOM_PORT" \
        --mode "$HEADROOM_MODE" \
        --code-aware \
        --lossless
    '';
  };

  status = writeShellApplication {
    name = "headroom-status";
    runtimeInputs = [curl];
    text = ''
      host="''${HEADROOM_HOST:-${bindAddress}}"
      port="''${HEADROOM_PORT:-${port}}"
      base="http://$host:$port"

      if curl -fsS "$base/readyz" >/dev/null 2>&1; then
        printf '%s\n' "Headroom ready: $base/readyz"
        exit 0
      fi

      if curl -fsS "$base/health" >/dev/null 2>&1; then
        printf '%s\n' "Headroom healthy: $base/health"
        exit 0
      fi

      exit 1
    '';
  };

  daemon = writeShellApplication {
    name = "headroom-daemon";
    runtimeInputs = [coreutils tmux start status];
    text = ''
      session="''${HEADROOM_SESSION:-${h.session}}"

      if tmux has-session -t "$session" 2>/dev/null; then
        if headroom-status >/dev/null 2>&1; then
          printf '%s\n' "Headroom is already ready in tmux session '$session'"
          exit 0
        fi
        tmux kill-session -t "$session" || true
      fi

      tmux new-session -d \
        -s "$session" \
        -e "HEADROOM_HOST=''${HEADROOM_HOST:-${bindAddress}}" \
        -e "HEADROOM_PORT=''${HEADROOM_PORT:-${port}}" \
        -e "HEADROOM_SAVINGS_PROFILE=''${HEADROOM_SAVINGS_PROFILE:-coding}" \
        -e "HEADROOM_MODE=''${HEADROOM_MODE:-token}" \
        -e "HEADROOM_CODE_AWARE_ENABLED=''${HEADROOM_CODE_AWARE_ENABLED:-1}" \
        -e "HEADROOM_LOSSLESS=''${HEADROOM_LOSSLESS:-1}" \
        -e "HEADROOM_TELEMETRY=''${HEADROOM_TELEMETRY:-on}" \
        -e "HEADROOM_PROVIDER_NAME=''${HEADROOM_PROVIDER_NAME:-9Router}" \
        -e "HEADROOM_WORKSPACE_DIR=''${HEADROOM_WORKSPACE_DIR:-${dataDir}}" \
        -e "HEADROOM_CONFIG_DIR=''${HEADROOM_CONFIG_DIR:-${configDir}}" \
        -e "HEADROOM_UV_CACHE=''${HEADROOM_UV_CACHE:-${cacheDir}/uv}" \
        -e "OPENAI_TARGET_API_URL=''${OPENAI_TARGET_API_URL:-}" \
        "headroom-start"

      i=0
      while [ "$i" -lt 60 ]; do
        if headroom-status >/dev/null 2>&1; then
          printf '%s\n' "Headroom is ready in tmux session '$session'"
          exit 0
        fi
        if ! tmux has-session -t "$session" 2>/dev/null; then
          printf '%s\n' "Headroom exited before becoming ready" >&2
          exit 1
        fi
        i=$((i + 1))
        sleep 1
      done

      printf '%s\n' "Headroom did not become ready within 60s" >&2
      exit 1
    '';
  };

  stop = writeShellApplication {
    name = "headroom-stop";
    runtimeInputs = [tmux];
    text = ''
      session="''${HEADROOM_SESSION:-${h.session}}"
      if tmux has-session -t "$session" 2>/dev/null; then
        tmux kill-session -t "$session"
      fi
    '';
  };
in {
  packagesStart = start;
  packages = [headroom start daemon stop status tmux gum curl lsof procps uv python313];

  env = {
    HEADROOM_HOST = bindAddress;
    HEADROOM_PORT = port;
    HEADROOM_BASE_URL = "http://${bindAddress}:${port}";
    HEADROOM_SAVINGS_PROFILE = "coding";
    HEADROOM_MODE = "token";
    HEADROOM_CODE_AWARE_ENABLED = "1";
    HEADROOM_LOSSLESS = "1";
    HEADROOM_TELEMETRY = "on";
    HEADROOM_PROVIDER_NAME = "9Router";
  };

  shellHook = ''
    export HEADROOM_WORKSPACE_DIR="''${HEADROOM_WORKSPACE_DIR:-${dataDir}}"
    export HEADROOM_CONFIG_DIR="''${HEADROOM_CONFIG_DIR:-${configDir}}"
    export HEADROOM_UV_CACHE="''${HEADROOM_UV_CACHE:-${cacheDir}/uv}"
    export HEADROOM_SESSION="''${HEADROOM_SESSION:-${h.session}}"
    export HEADROOM_BASE_URL="http://''${HEADROOM_HOST:-${bindAddress}}:''${HEADROOM_PORT:-${port}}"

    if [ -t 1 ]; then
      printf '%s\n' "Headroom context proxy: $HEADROOM_BASE_URL"
      printf '%s\n' "Commands: headroom-daemon | headroom-status | headroom-stop"
    fi
  '';
}
