{
  pkgs,
  cfg,
  paths,
  ...
}: let
  inherit (pkgs) curl gum lsof procps tmux uv writeShellApplication;

  h = cfg.headroom;
  bindAddress = h.bindAddress;
  port = toString h.port;
  dataDir = "${paths.xdg.data.local}/${cfg.directory}/${h.state}";
  cacheDir = "${paths.xdg.cache.local}/${cfg.directory}/${h.state}";
  version = "0.37.0";

  headroom = writeShellApplication {
    name = "headroom";
    runtimeInputs = [uv];
    text = ''
      export UV_CACHE_DIR="''${HEADROOM_UV_CACHE:-${cacheDir}/uv}"
      mkdir -p "$UV_CACHE_DIR"
      exec uvx --python 3.13 --from "headroom-ai[proxy]==${version}" headroom "$@"
    '';
  };

  start = writeShellApplication {
    name = "headroom-start";
    runtimeInputs = [headroom];
    text = ''
      export HEADROOM_HOST="''${HEADROOM_HOST:-${bindAddress}}"
      export HEADROOM_PORT="''${HEADROOM_PORT:-${port}}"
      export HEADROOM_TELEMETRY="''${HEADROOM_TELEMETRY:-off}"
      export HEADROOM_WORKSPACE="''${HEADROOM_WORKSPACE:-${dataDir}}"
      mkdir -p "$HEADROOM_WORKSPACE"
      exec headroom proxy --host "$HEADROOM_HOST" --port "$HEADROOM_PORT"
    '';
  };

  daemon = writeShellApplication {
    name = "headroom-daemon";
    runtimeInputs = [tmux start];
    text = ''
      session="''${HEADROOM_SESSION:-${h.session}}"
      if tmux has-session -t "$session" 2>/dev/null; then
        printf '%s\n' "Headroom already running in tmux session '$session'"
        exit 0
      fi
      tmux new-session -d -s "$session" "headroom-start"
      printf '%s\n' "Headroom started in tmux session '$session'"
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

  status = writeShellApplication {
    name = "headroom-status";
    runtimeInputs = [curl tmux lsof procps];
    text = ''
      port="''${HEADROOM_PORT:-${port}}"
      curl -fsS "http://${bindAddress}:$port/health"
    '';
  };
in {
  packages = [headroom start daemon stop status tmux gum curl lsof procps uv];

  env = {
    HEADROOM_HOST = bindAddress;
    HEADROOM_PORT = port;
    HEADROOM_BASE_URL = "http://${bindAddress}:${port}";
  };

  shellHook = ''
    export HEADROOM_WORKSPACE="''${HEADROOM_WORKSPACE:-${dataDir}}"
    export HEADROOM_UV_CACHE="''${HEADROOM_UV_CACHE:-${cacheDir}/uv}"
    export HEADROOM_SESSION="''${HEADROOM_SESSION:-${h.session}}"
    export HEADROOM_BASE_URL="http://${bindAddress}:''${HEADROOM_PORT:-${port}}"

    if [ -t 1 ]; then
      printf '%s\n' "Headroom context proxy: $HEADROOM_BASE_URL"
      printf '%s\n' "Commands: headroom-daemon | headroom-status | headroom-stop"
    fi
  '';
}
