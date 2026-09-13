{
  pkgs,
  cfg,
  ...
}: let
  inherit (pkgs) buildNpmPackage coreutils curl importNpmLock makeWrapper nodejs_22 tmux writeShellApplication;

  h = cfg.hindsight;
  version = h.version or "0.9.2";

  # v0.9.2 is the release behind the native API package used by this shell.
  # Pin the upstream source by commit so the Control Plane build is reproducible
  # and does not install npm dependencies at runtime.
  source = builtins.fetchGit {
    url = "https://github.com/vectorize-io/hindsight.git";
    rev = "ebad478240d3171bb88201ececda5e8d9883d22d";
  };

  controlPlane = buildNpmPackage {
    pname = "hindsight-control-plane";
    inherit version source;
    src = source;
    nodejs = nodejs_22;
    npmWorkspace = "hindsight-control-plane";
    npmDeps = importNpmLock {npmRoot = source;};
    npmConfigHook = importNpmLock.npmConfigHook;
    npmBuildScript = "build";
    nativeBuildInputs = [makeWrapper];
    NEXT_TELEMETRY_DISABLED = "1";

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib/hindsight-control-plane" "$out/bin"
      cp -r hindsight-control-plane/standalone/. "$out/lib/hindsight-control-plane/"
      makeWrapper ${nodejs_22}/bin/node "$out/bin/hindsight-control-plane" \
        --add-flags "$out/lib/hindsight-control-plane/server.js"
      runHook postInstall
    '';
  };

  start = writeShellApplication {
    name = "hindsight-ui-start";
    runtimeInputs = [controlPlane];
    text = ''
      : "''${HINDSIGHT_API_URL:?HINDSIGHT_API_URL not set}"
      : "''${HINDSIGHT_BIND_ADDRESS:?HINDSIGHT_BIND_ADDRESS not set}"
      : "''${HINDSIGHT_UI_PORT:?HINDSIGHT_UI_PORT not set}"

      export PORT="''${HINDSIGHT_UI_PORT}"
      export HOSTNAME="''${HINDSIGHT_BIND_ADDRESS}"
      export HINDSIGHT_CP_DATAPLANE_API_URL="''${HINDSIGHT_API_URL}"

      # local_external is unauthenticated unless the API is explicitly given
      # an auth key. Do not synthesize or require a Hindsight API key.
      if [ -n "''${HINDSIGHT_API_KEY:-}" ]; then
        export HINDSIGHT_CP_DATAPLANE_API_KEY="''${HINDSIGHT_API_KEY}"
      else
        unset HINDSIGHT_CP_DATAPLANE_API_KEY
      fi

      exec hindsight-control-plane \
        --hostname "$HOSTNAME" \
        --port "$PORT" \
        --api-url "$HINDSIGHT_CP_DATAPLANE_API_URL"
    '';
  };

  status = writeShellApplication {
    name = "hindsight-ui-status";
    runtimeInputs = [curl];
    text = ''
      : "''${HINDSIGHT_UI_URL:?HINDSIGHT_UI_URL not set}"
      curl -fsS "''${HINDSIGHT_UI_URL}" >/dev/null
      printf '%s\n' "Hindsight UI: ''${HINDSIGHT_UI_URL}"
    '';
  };

  daemon = writeShellApplication {
    name = "hindsight-ui-daemon";
    runtimeInputs = [coreutils tmux start status];
    text = ''
      : "''${HINDSIGHT_SESSION:?HINDSIGHT_SESSION not set}"
      session="''${HINDSIGHT_SESSION}-ui"

      if tmux has-session -t "$session" 2>/dev/null; then
        if hindsight-ui-status >/dev/null 2>&1; then
          printf '%s\n' "Hindsight UI is already ready in tmux session '$session'"
          exit 0
        fi
        tmux kill-session -t "$session" || true
      fi

      tmux new-session -d \
        -s "$session" \
        -e "HINDSIGHT_API_URL=''${HINDSIGHT_API_URL}" \
        -e "HINDSIGHT_UI_URL=''${HINDSIGHT_UI_URL}" \
        -e "HINDSIGHT_BIND_ADDRESS=''${HINDSIGHT_BIND_ADDRESS}" \
        -e "HINDSIGHT_UI_PORT=''${HINDSIGHT_UI_PORT}" \
        -e "HINDSIGHT_API_KEY=''${HINDSIGHT_API_KEY:-}" \
        "hindsight-ui-start"

      i=0
      while [ "$i" -lt 60 ]; do
        if hindsight-ui-status >/dev/null 2>&1; then
          printf '%s\n' "Hindsight UI is ready at ''${HINDSIGHT_UI_URL}"
          exit 0
        fi
        if ! tmux has-session -t "$session" 2>/dev/null; then
          printf '%s\n' "Hindsight UI exited before becoming ready" >&2
          exit 1
        fi
        i=$((i + 1))
        sleep 1
      done

      printf '%s\n' "Hindsight UI did not become ready within 60s" >&2
      exit 1
    '';
  };

  stop = writeShellApplication {
    name = "hindsight-ui-stop";
    runtimeInputs = [tmux];
    text = ''
      : "''${HINDSIGHT_SESSION:?HINDSIGHT_SESSION not set}"
      session="''${HINDSIGHT_SESSION}-ui"
      if tmux has-session -t "$session" 2>/dev/null; then
        tmux kill-session -t "$session"
      fi
    '';
  };
in {
  packages = [controlPlane start status daemon stop];
}
