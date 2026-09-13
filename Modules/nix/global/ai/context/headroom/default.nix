{
  pkgs,
  cfg,
  paths,
  ...
}: let
  inherit (pkgs) curl gum lsof procps python313 tmux uv writeShellApplication;
  inherit (pkgs.lib) makeLibraryPath;

  h = cfg.headroom;
  bindAddress = h.bindAddress;
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
      exec uvx --python ${python313}/bin/python3.13 --from "headroom-ai[proxy]==${version}" headroom "$@"
    '';
  };

  start = writeShellApplication {
    name = "headroom-start";
    runtimeInputs = [headroom];
    text = ''
      export HEADROOM_HOST="''${HEADROOM_HOST:-${bindAddress}}"
      export HEADROOM_PORT="''${HEADROOM_PORT:-${port}}"
      export HEADROOM_TELEMETRY="''${HEADROOM_TELEMETRY:-off}"
      export HEADROOM_WORKSPACE_DIR="''${HEADROOM_WORKSPACE_DIR:-${dataDir}}"
      export HEADROOM_CONFIG_DIR="''${HEADROOM_CONFIG_DIR:-${configDir}}"
      mkdir -p "$HEADROOM_WORKSPACE_DIR" "$HEADROOM_CONFIG_DIR"
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
  packages = [headroom start daemon stop status tmux gum curl lsof procps uv python313];

  env = {
    HEADROOM_HOST = bindAddress;
    HEADROOM_PORT = port;
    HEADROOM_BASE_URL = "http://${bindAddress}:${port}";
  };

  shellHook = ''
    export HEADROOM_WORKSPACE_DIR="''${HEADROOM_WORKSPACE_DIR:-${dataDir}}"
    export HEADROOM_CONFIG_DIR="''${HEADROOM_CONFIG_DIR:-${configDir}}"
    export HEADROOM_UV_CACHE="''${HEADROOM_UV_CACHE:-${cacheDir}/uv}"
    export HEADROOM_SESSION="''${HEADROOM_SESSION:-${h.session}}"
    export HEADROOM_BASE_URL="http://${bindAddress}:''${HEADROOM_PORT:-${port}}"

    if [ -t 1 ]; then
      printf '%s\n' "Headroom context proxy: $HEADROOM_BASE_URL"
      printf '%s\n' "Commands: headroom-daemon | headroom-status | headroom-stop"
    fi
  '';
}
