{pkgs, ...}: let
  inherit (pkgs.lib.strings) concatMapStringsSep;
  inherit
    (pkgs)
    cacert
    curl
    gum
    lsof
    nodejs_22
    patch
    procps
    sqlite
    tmux
    writeShellApplication
    ;
  nodejs = nodejs_22;

  omnirouteVersion = "3.8.49";

  gums = ''
    fmt_accent()  { gum style --foreground 212 "$@"; }
    fmt_warn()    { gum style --foreground 214 "$@"; }
    fmt_success() { gum style --foreground 82 --bold "$@"; }
    fmt_err()     { gum style --foreground 196 "$@"; }
    fmt_muted()   { gum style --foreground 244 "$@"; }
    fmt_faint()   { printf "%s\n" "$(gum style --faint "$@")"; }
  '';

  menu = concatMapStringsSep "\n" (item: "  $(fmt_accent '${item.cmd}')   ${item.desc}") [
    {
      cmd = "omniroute-daemon";
      desc = "start OmniRoute detached in tmux (idempotent)";
    }
    {
      cmd = "omniroute-status";
      desc = "check OmniRoute and its OpenAI-compatible endpoint";
    }
    {
      cmd = "omniroute-stop";
      desc = "stop the OmniRoute tmux session";
    }
    {
      cmd = "omniroute-policy";
      desc = "reconcile dynamic-route compatibility exclusions";
    }
    {
      cmd = "omniroute-start";
      desc = "run OmniRoute in the foreground";
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

  omniroute = writeShellApplication {
    name = "omniroute";
    runtimeInputs = [
      nodejs
      cacert
      patch
    ];
    text = ''
      cache_dir="''${OMNIROUTE_NPX_CACHE:-''${XDG_CACHE_HOME:-$HOME/.cache}/omniroute/npx}"
      mkdir -p "$cache_dir/npm-cache"
      NPM_CONFIG_CACHE="$cache_dir/npm-cache"
      NPM_CONFIG_UPDATE_NOTIFIER=false
      NODE_EXTRA_CA_CERTS="${cacert}/etc/ssl/certs/ca-bundle.crt"
      OMNIROUTE_NPX_CACHE="$cache_dir"
      OMNIROUTE_CODEX_RESPONSES_PATCH="${./codex-responses-reasoning.patch}"
      OMNIROUTE_CODEX_EXECUTOR_PATCH="${./codex-executor-reasoning.patch}"
      OMNIROUTE_CODEX_TARGET_PATCH="${./codex-target-sanitizer.patch}"
      OMNIROUTE_CODEX_SERIALIZATION_PATCH="${./codex-base-serialization.patch}"
      export NPM_CONFIG_CACHE NPM_CONFIG_UPDATE_NOTIFIER NODE_EXTRA_CA_CERTS
      export OMNIROUTE_NPX_CACHE OMNIROUTE_CODEX_RESPONSES_PATCH OMNIROUTE_CODEX_EXECUTOR_PATCH OMNIROUTE_CODEX_TARGET_PATCH OMNIROUTE_CODEX_SERIALIZATION_PATCH
      ${nodejs}/bin/npx --yes "omniroute@${omnirouteVersion}" --version >/dev/null
      ${pkgs.runtimeShell} ${./apply-codex-responses-patch.sh}
      exec ${nodejs}/bin/npx --yes "omniroute@${omnirouteVersion}" "$@"
    '';
  };

  policy = writeShellApplication {
    name = "omniroute-policy";
    runtimeInputs = [sqlite];
    text = ''exec ${pkgs.runtimeShell} ${./policy.sh}'';
  };

  start = writeShellApplication {
    name = "omniroute-start";
    runtimeInputs = [
      omniroute
      policy
      gum
    ];
    text = ''
      ${gums}
      data_dir="''${OMNIROUTE_DATA_DIR:-''${XDG_DATA_HOME:-$HOME/.local/share}/omniroute}"
      export DATA_DIR="$data_dir"
      export OMNIROUTE_DATA_DIR="$data_dir"
      mkdir -p "$data_dir"
      omniroute-policy
      port="''${OMNIROUTE_PORT:-20128}"
      export PORT="$port"
      fmt_accent --bold "OmniRoute starting -> http://127.0.0.1:$port"
      fmt_faint "OpenAI-compatible API: http://127.0.0.1:$port/v1"
      exec omniroute "$@"
    '';
  };

  daemon = writeShellApplication {
    name = "omniroute-daemon";
    runtimeInputs = [
      tmux
      start
      gum
    ];
    text = ''
      ${gums}
      session="''${OMNIROUTE_SESSION:-omniroute}"
      if tmux has-session -t "$session" 2>/dev/null; then
        fmt_warn "OmniRoute is already running in tmux session '$session'"
        fmt_faint "Attach with: tmux attach -t $session"
        exit 0
      fi
      tmux new-session -d -s "$session" "omniroute-start"
      fmt_success "OmniRoute started in detached tmux session '$session'"
      fmt_faint "Attach with: tmux attach -t $session"
      fmt_faint "Stop with:   omniroute-stop"
    '';
  };

  stop = writeShellApplication {
    name = "omniroute-stop";
    runtimeInputs = [
      tmux
      gum
    ];
    text = ''
      ${gums}
      session="''${OMNIROUTE_SESSION:-omniroute}"
      if tmux has-session -t "$session" 2>/dev/null; then
        tmux kill-session -t "$session"
        fmt_err "OmniRoute stopped"
      else
        fmt_muted "OmniRoute is not running in tmux"
      fi
    '';
  };

  status = writeShellApplication {
    name = "omniroute-status";
    runtimeInputs = [
      tmux
      curl
      gum
      lsof
      procps
    ];
    text = ''
      ${gums}
      session="''${OMNIROUTE_SESSION:-omniroute}"
      port="''${OMNIROUTE_PORT:-20128}"
      if tmux has-session -t "$session" 2>/dev/null; then
        printf "%s %s\n" "$(fmt_success "●")" "tmux session: running ('$session')"
      else
        printf "%s %s\n" "$(fmt_err "○")" "tmux session: not running ('$session')"
      fi
      if curl -fsS "http://127.0.0.1:$port/v1/models" -o /dev/null 2>/dev/null; then
        printf "%s %s\n" "$(fmt_success "●")" "OpenAI endpoint: up (http://127.0.0.1:$port/v1)"
      else
        printf "%s %s\n" "$(fmt_err "○")" "OpenAI endpoint: not responding on port $port"
      fi
    '';
  };
in {
  inherit
    omniroute
    policy
    start
    daemon
    stop
    status
    ;

  packages = [
    omniroute
    policy
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
  ];

  env = {
    OMNIROUTE_PORT = "20128";
    OMNIROUTE_BASE_URL = "http://127.0.0.1:20128/v1";
  };

  shellHook = ''
    export OMNIROUTE_DATA_DIR="''${OMNIROUTE_DATA_DIR:-''${XDG_DATA_HOME:-$HOME/.local/share}/omniroute}"
    export OMNIROUTE_NPX_CACHE="''${OMNIROUTE_NPX_CACHE:-''${XDG_CACHE_HOME:-$HOME/.cache}/omniroute/npx}"
    export OMNIROUTE_SESSION="''${OMNIROUTE_SESSION:-omniroute}"
    export OMNIROUTE_BASE_URL="http://127.0.0.1:''${OMNIROUTE_PORT:-20128}/v1"

    if [ -t 1 ]; then
      ${mkMenuBox "OmniRoute Development Shell" "Local OpenAI-compatible model router"}
    fi
  '';
}
