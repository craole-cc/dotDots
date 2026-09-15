{
  pkgs,
  cfg,
  ...
}: let
  inherit (pkgs) coreutils curl fetchurl makeWrapper nodejs_22 stdenvNoCC tmux writeShellApplication;

  version = cfg.hindsight.version or "0.9.2";

  # Upstream publishes the Control Plane as a release tarball containing the
  # already-built Next.js standalone tree. Package that immutable artifact
  # directly instead of re-resolving the monorepo's npm workspaces in Nix.
  controlPlane = stdenvNoCC.mkDerivation {
    pname = "hindsight-control-plane";
    inherit version;

    src = fetchurl {
      url = "https://github.com/vectorize-io/hindsight/releases/download/v${version}/vectorize-io-hindsight-control-plane-${version}.tgz";
      hash = "sha256-lU0lSqHsnG0UXcsq/j7C1wo8J11arQW56mhLSTI6i3g=";
    };

    nativeBuildInputs = [makeWrapper];
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib/hindsight-control-plane" "$out/bin"
      cp -r standalone/. "$out/lib/hindsight-control-plane/"
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

      exec hindsight-control-plane
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
  inherit start;
  packages = [controlPlane start status daemon stop];
}
