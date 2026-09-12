{
  pkgs,
  system,
  paths,
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
  env = {
    NIX_CONFIG = "experimental-features = nix-command flakes";
    SYSTEM = system;
  };

  #? Shared runtime setup for shells that reuse the core environment.
  #? The interactive environment owns DOTS. Host schema paths are only the
  #? fallback when a caller has not already selected a checkout.
  runtimeHook = ''
    DOTS="''${DOTS:-${paths.repo.src.local}}"
    DOTS_LIB_SH="''${DOTS_LIB_SH:-$DOTS/Libraries/posix}"
    DOTS_CACHE="''${DOTS_CACHE:-$DOTS/.cache}"
    export DOTS DOTS_LIB_SH DOTS_CACHE

    HOSTNAME="$(hostname)"
    HOSTTYPE="${system}"
    export HOSTNAME HOSTTYPE

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

    case ":$PATH:" in
      *":$ENV_BIN:"*) ;;
      *) PATH="$ENV_BIN:$PATH" ;;
    esac

    #> NixOS privileged programs must resolve through the host wrapper tree.
    #> Do not mirror privileged commands into persistent project state.
    if [ -d /run/wrappers/bin ]; then
      case "$PATH" in
        /run/wrappers/bin:*) ;;
        *) PATH="/run/wrappers/bin:$PATH" ;;
      esac
      export PATH
      hash -r 2>/dev/null || true
    fi
  '';

  shellHook = runtimeHook + ''
    #> Initialize bin directories with binit if available
    BINIT_PATH="$DOTS_LIB_SH/base/binit"
    if [ -f "''${BINIT_PATH:-}" ]; then
      if [ -x "$BINIT_PATH" ]; then :; else chmod +x "$BINIT_PATH"; fi
      . "$BINIT_PATH"
    else
      printf "direnv: binit not found at %s\n" "''${BINIT_PATH}" >&2
    fi

    #> binit may prepend repository library paths; restore the host wrapper
    #> directory to the front without creating sudo/su shims.
    if [ -d /run/wrappers/bin ]; then
      case "$PATH" in
        /run/wrappers/bin:*) ;;
        *) PATH="/run/wrappers/bin:$PATH" ;;
      esac
      export PATH
      hash -r 2>/dev/null || true
    fi

    #> Initialize yazi from the active DOTS checkout.
    YAZI_INIT="$DOTS/Configuration/yazi/init.sh"
    if [ -f "$YAZI_INIT" ]; then
      . "$YAZI_INIT"
    else
      printf "yazi: init.sh not found at %s\n" "$YAZI_INIT" >&2
    fi

    #> Use starship for prompt from the active DOTS checkout.
    if cmd-exists starship; then
      STARSHIP_CONFIG="$DOTS/Configuration/starship/config.toml"
      export STARSHIP_CONFIG
      eval "$(starship init bash)"
    fi

    #> Display shell information with the defined fetcher
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
