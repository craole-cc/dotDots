{
  pkgs,
  cfg,
  paths,
  ...
}: let
  inherit (pkgs) cacert coreutils curl lsof nodejs_22 procps tailscale tmux writeShellApplication;

  r = cfg.nineRouter;
  inherit (r) bindAddress;
  port = toString r.port;
  dataDir = "${paths.xdg.data.local}/${cfg.directory}/${r.state}";
  cacheDir = "${paths.xdg.cache.local}/${cfg.directory}/${r.state}/npm";
  version = "0.5.75";

  router9 = writeShellApplication {
    name = "9router";
    # 9Router discovers Tailscale at runtime when its optional Funnel support
    # is opened in the dashboard. Keep the CLI in this launcher’s Nix path so
    # it matches the declarative system daemon instead of an incidental user
    # profile version.
    runtimeInputs = [nodejs_22 cacert tailscale];
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
      exec 9router --host "$HOSTNAME" --port "$PORT" --no-browser --skip-update
    '';
  };

  status = writeShellApplication {
    name = "9router-status";
    runtimeInputs = [curl];
    text = ''
      host="''${NINE_ROUTER_BIND_ADDRESS:-${bindAddress}}"
      port="''${NINE_ROUTER_PORT:-${port}}"
      curl -fsS "http://$host:$port/v1/models" -o /dev/null
      printf '%s\n' "9Router OpenAI endpoint: http://$host:$port/v1"
    '';
  };

  daemon = writeShellApplication {
    name = "9router-daemon";
    runtimeInputs = [coreutils tmux start status];
    text = ''
      session="''${NINE_ROUTER_SESSION:-${r.session}}"

      if tmux has-session -t "$session" 2>/dev/null; then
        if 9router-status >/dev/null 2>&1; then
          printf '%s\n' "9Router is already ready in tmux session '$session'"
          exit 0
        fi
        tmux kill-session -t "$session" || true
      fi

      tmux new-session -d \
        -s "$session" \
        -e "NINE_ROUTER_DATA_DIR=''${NINE_ROUTER_DATA_DIR:-${dataDir}}" \
        -e "NINE_ROUTER_NPM_CACHE=''${NINE_ROUTER_NPM_CACHE:-${cacheDir}}" \
        -e "NINE_ROUTER_PORT=''${NINE_ROUTER_PORT:-${port}}" \
        -e "NINE_ROUTER_BIND_ADDRESS=''${NINE_ROUTER_BIND_ADDRESS:-${bindAddress}}" \
        "9router-start"

      i=0
      while [ "$i" -lt 90 ]; do
        if 9router-status >/dev/null 2>&1; then
          printf '%s\n' "9Router is ready in tmux session '$session'"
          exit 0
        fi
        if ! tmux has-session -t "$session" 2>/dev/null; then
          printf '%s\n' "9Router exited before becoming ready" >&2
          exit 1
        fi
        i=$((i + 1))
        sleep 1
      done

      printf '%s\n' "9Router did not become ready within 90s" >&2
      exit 1
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
in {
  packagesStart = start;
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
