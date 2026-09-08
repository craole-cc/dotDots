{
  pkgs,
  system,
  fetch,
  formatters,
  isLinux,
  isDarwin,
  cmdExists,
  optionals,
  ...
}: let
  description = "Core Environment";

  #|---------------------------------------------------------|
  #| Packages -----------------------------------------------|
  #|---------------------------------------------------------|
  packages =
    [
      cmdExists
      fetch
    ]
    ++ (
      with pkgs;
        [
          age # ? Encrypting and decrypting files and messages
          alejandra # ? Nix code formatter
          bat # ? Cat clone with syntax highlighting
          direnv # ? Environment variable manager
          fastfetch # ? Fast system information fetcher
          fd # ? Fast find alternative
          gh # ? GitHub CLI
          git # ? Git version control system
          gnused # ? GNU stream editor
          gum # ? Toolkit for building pretty CLI applications
          jq # ? JSON query processor
          lsd # ? LSDeluxe file lister
          nixd # ? Nix language daemon
          onefetch # ? Git repository summary on your terminal
          ripgrep # ? Fast grep alternative
          ripgrep-all # ? Ripgrep, for PDFs, E-Books, Office documents, zip, tar.gz, etc.
          sd # ? Intuitive find & replace CLI (sed alternative)
          sops # ? Secrets OPerationS, for managing secrets
          undollar # ? Remove leading dollar signs age
        ]
        ++ optionals isLinux [
          xclip # ? Command line interface to the X11 clipboard
          wl-clipboard # ? Command line interface to the Wayland clipboard
          xsel # ? Command line interface to the X11 selection buffer
        ]
        ++ optionals isDarwin [
          pbcopy # ? Command line interface to the macOS clipboard
          pbpaste # ? Command line interface to the macOS clipboard
        ]
        ++ formatters # ? Formatter packages plus the wrapper
    );

  #|---------------------------------------------------------|
  #| Shell Configuration  -----------------------------------|
  #|---------------------------------------------------------|
  #? Per-system devShells are not host-specific, so local checkout paths
  #? must be resolved when the shell starts instead of being baked into
  #? the derivation from whichever host happened to drive flake evaluation.
  env = {
    NIX_CONFIG = "experimental-features = nix-command flakes";
    SYSTEM = system;
  };

  runtimeHook = ''
    #> Resolve the active dotDots checkout without consulting Git state.
    #> This intentionally uses only shell/filesystem semantics: DOTS is a
    #> runtime path and therefore cannot be recovered from a pure flake's
    #> store path. Prefer the nearest ancestor with the dotDots root markers;
    #> fall back to an already-valid DOTS when the shell is entered elsewhere.
    _dots_root_of() {
      _dots_dir="''${1:-''${PWD:-.}}"
      _dots_dir="$(cd "$_dots_dir" 2>/dev/null && pwd -P)" || return 1

      while :; do
        if [ -f "$_dots_dir/flake.nix" ] \
          && [ -f "$_dots_dir/profile" ] \
          && [ -d "$_dots_dir/API/nix" ] \
          && [ -d "$_dots_dir/Modules/nix" ] \
          && [ -d "$_dots_dir/Libraries/nix" ]; then
          printf '%s\n' "$_dots_dir"
          return 0
        fi

        [ "$_dots_dir" = "/" ] && return 1
        _dots_parent="''${_dots_dir%/*}"
        [ -n "$_dots_parent" ] || _dots_parent="/"
        [ "$_dots_parent" = "$_dots_dir" ] && return 1
        _dots_dir="$_dots_parent"
      done
    }

    if _dots_root="$(_dots_root_of "''${PWD:-.}")"; then
      DOTS="$_dots_root"
    elif [ -n "''${DOTS:-}" ] && _dots_root="$(_dots_root_of "$DOTS")"; then
      DOTS="$_dots_root"
    else
      printf 'dotDots: unable to resolve repository root from PWD=%s or DOTS=%s\n' \
        "''${PWD:-}" "''${DOTS:-}" >&2
      return 1
    fi

    DOTS_CFG="$DOTS/Configuration"
    DOTS_LIB="$DOTS/Libraries"
    DOTS_LIB_SH="$DOTS_LIB/posix"
    DOTS_CACHE="$DOTS/.cache"
    export DOTS DOTS_CFG DOTS_LIB DOTS_LIB_SH DOTS_CACHE
    unset _dots_root _dots_dir _dots_parent
    unset -f _dots_root_of 2>/dev/null || true

    #> Determine host info dynamically.
    HOSTNAME="$(hostname)"
    HOSTTYPE="${system}"
    export HOSTNAME HOSTTYPE

    #> Set up cache directory structure.
    ENV_BIN="$DOTS_CACHE/bin"
    DOTS_LOGS="$DOTS_CACHE/logs"
    DOTS_TMP="$DOTS_CACHE/tmp"
    mkdir -p "$ENV_BIN" "$DOTS_LOGS" "$DOTS_TMP"
    export ENV_BIN DOTS_LOGS DOTS_TMP

    nix-check() {
      local log status
      log=$(mktemp)

      nix flake check --show-trace --verbose 2>&1 | tee "$log"
      status="''${PIPESTATUS[0]}"

      rm -f "$log"
      return "$status"
    }

    #> Add the repo-local bin directory to PATH.
    case ":$PATH:" in
      *":$ENV_BIN:"*) ;;
      *) PATH="$ENV_BIN:$PATH" ;;
    esac

    #> On NixOS, privileged wrappers must win over the unprivileged
    #> package binaries. Rootless Podman depends on the setuid newuidmap /
    #> newgidmap wrappers, and sudo must resolve through the wrapper too.
    if [ -d /run/wrappers/bin ]; then
      case ":$PATH:" in
        :/run/wrappers/bin:*) ;;
        *) PATH="/run/wrappers/bin:$PATH" ;;
      esac
    fi
    export PATH
  '';

  shellHook = runtimeHook + ''
    #> Initialize bin directories with binit if available.
    BINIT_PATH="$DOTS_LIB_SH/base/binit"
    if [ -f "''${BINIT_PATH:-}" ]; then
      if [ -x "$BINIT_PATH" ]; then :; else chmod +x "$BINIT_PATH"; fi
      . "$BINIT_PATH"
    else
      printf "direnv: binit not found at %s\n" "''${BINIT_PATH}" >&2
    fi

    #> binit prepends repo library directories; restore NixOS wrapper
    #> precedence afterwards so privileged commands cannot be shadowed.
    if [ -d /run/wrappers/bin ]; then
      PATH="/run/wrappers/bin:$PATH"
      export PATH
    fi

    #> Initialize yazi.
    YAZI_INIT="$DOTS_CFG/yazi/init.sh"
    if [ -f "$YAZI_INIT" ]; then
      . "$YAZI_INIT"
    else
      printf "yazi: init.sh not found at %s\n" "$YAZI_INIT" >&2
    fi

    #> Use starship for prompt.
    if cmd-exists starship; then
      STARSHIP_CONFIG="$DOTS_CFG/starship/config.toml"
      export STARSHIP_CONFIG
      eval "$(starship init bash)"
    fi

    #> Display shell information with the defined fetcher.
    if [ -t 1 ]; then
      ${fetch.name}
    fi
  '';
in {
  inherit
    description
    packages
    env
    runtimeHook
    shellHook
    ;
}
