{
  pkgs,
  cfg,
  paths,
  ...
}: let
  inherit (pkgs) cacert curl lsof nodejs_22 procps tmux writeShellApplication;

  r = cfg.nineRouter;
  bindAddress = r.bindAddress;
  port = toString r.port;
  dataDir = "${paths.xdg.data.local}/${cfg.directory}/${r.state}";
  cacheDir = "${paths.xdg.cache.local}/${cfg.directory}/${r.state}/npm";
  version = "0.5.75";

  router9 = writeShellApplication {
    name = "9router";
    runtimeInputs = [nodejs_22 cacert];
    text = ''
      export NPM_CONFIG_CACHE="''${NINE_ROUTER_NPM_CACHE:-${cacheDir}}"
      export NPM_CONFIG_UPDATE_NOTIFIER=false
      export NODE_EXTRA_CA_CERTS="${cacert}/etc/ssl/certs/ca-bundle.crt"
      mkdir -p "$NPM_CONFIG_CACHE"
      exec ${nodejs_22}/bin/npx --yes "9router@${version}" "$@"
    '';
  };

  start = writeShellApplication {
    name = "9router-start";
    runtimeInputs = [router9];
    text = ''
      export DATA_DIR="''${NINE_ROUTER_DATA_DIR:-${dataDir}}"
      export PORT="''${NINE_ROUTER_PORT:-${port}}"
      export HOSTNAME="''${NINE_ROUTER_BIND_ADDRESS:-${bindAddress}}"
      mkdir -p "$DATA_DIR"
      exec 9router --port "$PORT" --no-browser --skip-update
    '';
  };

  daemon = writeShellApplication {
    name = "9router-daemon";
    runtimeInputs = [tmux start];
    text = ''
      session="''${NINE_ROUTER_SESSION:-${r.session}}"
      if tmux has-session -t "$session" 2>/dev/null; then
        printf '%s\n' "9Router already running in tmux session '$session'"
        exit 0
      fi
      tmux new-session -d -s "$session" "9router-start"
      printf '%s\n' "9Router started in tmux session '$session'"
    '';
  };

  stop = writeShellApplication {
    name = "9router-stop";
    runtimeInputs = [tmux];
    text = ''
      session="''${NINE_ROUTER_SESSION:-${r.session}}"
      if tmux has-session -t "$session" 2>/dev/null; then
        tmux kill-session -t "$session"
      fi
    '';
  };

  status = writeShellApplication {
    name = "9router-status";
    runtimeInputs = [curl tmux lsof procps];
    text = ''
      port="''${NINE_ROUTER_PORT:-${port}}"
      curl -fsS "http://${bindAddress}:$port/v1/models" -o /dev/null
      printf '%s\n' "9Router OpenAI endpoint: http://${bindAddress}:$port/v1"
    '';
  };
in {
  packages = [router9 start daemon stop status tmux curl lsof procps nodejs_22];

  env = {
    NINE_ROUTER_PORT = port;
    NINE_ROUTER_BIND_ADDRESS = bindAddress;
    NINE_ROUTER_BASE_URL = "http://${bindAddress}:${port}/v1";
  };

  shellHook = ''
    export NINE_ROUTER_DATA_DIR="''${NINE_ROUTER_DATA_DIR:-${dataDir}}"
    export NINE_ROUTER_NPM_CACHE="''${NINE_ROUTER_NPM_CACHE:-${cacheDir}}"
    export NINE_ROUTER_SESSION="''${NINE_ROUTER_SESSION:-${r.session}}"
    export NINE_ROUTER_BASE_URL="http://''${NINE_ROUTER_BIND_ADDRESS:-${bindAddress}}:''${NINE_ROUTER_PORT:-${port}}/v1"

    if [ -t 1 ]; then
      printf '%s\n' "9Router: $NINE_ROUTER_BASE_URL"
      printf '%s\n' "Commands: 9router-daemon | 9router-status | 9router-stop"
    fi
  '';
}
