args: let
  inherit (args) pkgs pkgsFor;
  inherit (pkgs.lib.strings) concatMapStringsSep;
  inherit
    (pkgs)
    cacert
    curl
    gum
    lsof
    nodejs_22
    procps
    tmux
    writeShellApplication
    ;
  nodejs = nodejs_22;

  agentPackages =
    (pkgsFor {
      sources = {
        openclaw = "llm-agents";
        opencode = "llm-agents";
      };
    }).packages;

  /**
  Shared configuration
  */
  omnirouteVersion = "3.8.49";
  npxCacheDir = "$HOME/.cache/omniroute-flake/npx";
  dataDir = "$HOME/.local/share/omniroute";

  /**
  Shared Shell Helpers
  */
  gums = ''
    fmt_accent()  { gum style --foreground 212 "$@"; }
    fmt_warn()    { gum style --foreground 214 "$@"; }
    fmt_success() { gum style --foreground 82 --bold "$@"; }
    fmt_err()     { gum style --foreground 196 "$@"; }
    fmt_muted()   { gum style --foreground 244 "$@"; }
    fmt_faint()   { printf "%s\n" "$(gum style --faint "$@")"; }
  '';

  /**
  Command menu, printed by the router shellHook.
  */
  menu = concatMapStringsSep "\n" (item: "  $(fmt_accent '${item.cmd}')   ${item.desc}") [
    {
      cmd = "air-daemon";
      desc = "start air gateway detached in tmux (idempotent)";
    }
    {
      cmd = "air-status";
      desc = "check if air gateway is running";
    }
    {
      cmd = "air-stop";
      desc = "kill the air tmux session";
    }
    {
      cmd = "air-start";
      desc = "run air gateway in the foreground";
    }
  ];

  mkMenuBox = title: subtitle: ''
    ${gums}
    gum style \
      --border normal \
      --margin "1" \
      --padding "1" \
      --border-foreground 212 \
      "$(fmt_accent --bold '${title}')" \
      "$(fmt_faint '${subtitle}')" \
      "" \
      "$(gum style --bold 'Commands available:')" \
      "${menu}"
  '';

  gateway = writeShellApplication {
    name = "air";
    runtimeInputs = [
      nodejs
      cacert
    ];
    text = ''
      NPM_CONFIG_CACHE="${npxCacheDir}/npm-cache"
      NPM_CONFIG_UPDATE_NOTIFIER=false
      NODE_EXTRA_CA_CERTS="${cacert}/etc/ssl/certs/ca-bundle.crt"
      export NPM_CONFIG_CACHE NPM_CONFIG_UPDATE_NOTIFIER NODE_EXTRA_CA_CERTS
      exec ${nodejs}/bin/npx --yes "omniroute@${omnirouteVersion}" "$@"
    '';
  };

  start = writeShellApplication {
    name = "air-start";
    runtimeInputs = [
      gateway
      gum
    ];
    text = ''
      ${gums}
      export DATA_DIR="${dataDir}"
      mkdir -p "$DATA_DIR"
      PORT_NUM="''${PORT:-20128}"
      fmt_accent --bold "air gateway starting -> http://localhost:$PORT_NUM"
      fmt_faint "Dashboard/API on the same port unless PORT/DASHBOARD_PORT overridden."
      exec air "$@"
    '';
  };

  daemon = writeShellApplication {
    name = "air-daemon";
    runtimeInputs = [
      tmux
      start
      gum
    ];
    text = ''
      ${gums}
      SESSION="air"
      if tmux has-session -t "$SESSION" 2>/dev/null; then
        fmt_warn "air daemon already running in tmux session '$SESSION'"
        fmt_faint "Attach with: tmux attach -t $SESSION"
        exit 0
      fi
      tmux new-session -d -s "$SESSION" "air-run"
      fmt_success "air daemon started in detached tmux session '$SESSION'"
      fmt_faint "Attach with: tmux attach -t $SESSION"
      fmt_faint "Stop with:   air-stop"
    '';
  };

  stop = writeShellApplication {
    name = "air-stop";
    runtimeInputs = [
      tmux
      gum
    ];
    text = ''
      ${gums}
      SESSION="air"
      if tmux has-session -t "$SESSION" 2>/dev/null; then
        tmux kill-session -t "$SESSION"
        fmt_err "air daemon stopped"
      else
        fmt_muted "air daemon is not running in tmux"
      fi
    '';
  };

  status = writeShellApplication {
    name = "air-status";
    runtimeInputs = [
      tmux
      curl
      gum
      lsof
      procps
    ];
    text = ''
      ${gums}
      SESSION="air"
      PORT_TO_CHECK="''${PORT:-20128}"
      if tmux has-session -t "$SESSION" 2>/dev/null; then
        printf "%s %s\n" "$(fmt_success "●")" "tmux session: running ('$SESSION')"
      else
        printf "%s %s\n" "$(fmt_err "○")" "tmux session: not running ('$SESSION')"
      fi
      if curl -fsS "http://localhost:''${PORT_TO_CHECK}/v1" -o /dev/null 2>/dev/null; then
        printf "%s %s\n" "$(fmt_success "●")" "http endpoint: up (http://localhost:''${PORT_TO_CHECK})"
        if ! tmux has-session -t "$SESSION" 2>/dev/null; then
          fmt_warn "  (endpoint is up but not inside the '$SESSION' tmux session — likely an orphaned process)"
          if command -v lsof >/dev/null 2>&1; then
            lsof -i ":''${PORT_TO_CHECK}" -sTCP:LISTEN 2>/dev/null | tail -n +2 | while read -r _ pid _; do
              fmt_faint "  PID $pid — kill it with: kill $pid"
            done
          fi
        fi
      else
        printf "%s %s\n" "$(fmt_err "○")" "http endpoint: not responding on port ''${PORT_TO_CHECK}"
      fi
    '';
  };
in {
  packages =
    [
      gateway
      start
      daemon
      stop
      status
      tmux
      gum
      nodejs
      lsof
      procps
      curl
    ]
    ++ agentPackages;

  env = {
    AIR_PORT = "20128";
    AIR_BASE_URL = "http://localhost:20128/v1";
  };

  shellHook = ''
    ${mkMenuBox "ai-router dev shell" "air/OmniRoute gateway + openclaw + opencode"}
    air-daemon || true
  '';
}
