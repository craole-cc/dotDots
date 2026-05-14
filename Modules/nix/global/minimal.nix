{ dots, ... }:
let
  description = "Minimal Dev Environment";
  inherit (dots)
    cache
    lix
    pkgs
    system
    ;
  inherit (lix.lists.construction) optionals;

  #|────────────────────────────────────────|
  #| Packages                               |
  #|────────────────────────────────────────|

  packages =
    with pkgs;
    [
      bat # ? Cat clone with syntax highlighting
      fd # ? Fast find alternative
      gnused # ? GNU stream editor
      jq # ? JSON query processor
      lsd # ? LSDeluxe file lister
      nitch # ? System fetch written in nim
      nixd # ? Nix language daemon
      ripgrep-all # ? Fast grep alternative
      sd # ? Intuitive find & replace CLI (sed alternative)
      onefetch # ? Git repository summary on your terminal
      undollar # ? Remove leading dollar signs
    ]
    ++ optionals stdenv.isLinux [
      xclip
      wl-clipboard
      xsel
    ];
  #|────────────────────────────────────────|
  #| Shell Configuration                    |
  #|────────────────────────────────────────|
  env = {
    NIX_CONFIG = "experimental-features = nix-command flakes";
    SYSTEM = system;
  };

  shellHook = ''
    #> Determine host info dynamically
    HOSTNAME="$(hostname)"
    HOSTTYPE="${system}"
    export HOSTNAME HOSTTYPE

    #> Ensure DOTS directories are defined
    if [ -z "$DOTS" ]; then
      DOTS="$(pwd -P)"
      export DOTS
    fi

    if [ -z "$DOTS_LIB_SH" ]; then
      DOTS_LIB_SH="$DOTS/Libraries/shellscript"
      export DOTS_LIB_SH
    fi

    if [ -z "$DOTS_CACHE" ]; then
      DOTS_CACHE="$DOTS/${cache}"
      export DOTS_CACHE
    fi

    #> Set up cache directory structure
    ENV_BIN="$DOTS_CACHE/bin"
    DOTS_LOGS="$DOTS_CACHE/logs"
    DOTS_TMP="$DOTS_CACHE/tmp"
    mkdir -p "$ENV_BIN" "$DOTS_LOGS" "$DOTS_TMP"
    export DOTS_CACHE DOTS_LOGS DOTS_TMP

    #> Add bin directory to PATH
    case ":$PATH:" in
      *":$ENV_BIN:"*) ;;
      *) PATH="$ENV_BIN:$PATH" ;;
    esac
    export PATH

    #> Initialize bin directories with binit if available
    BINIT_PATH="$DOTS_LIB_SH/base/binit"
    if [ -f "''${BINIT_PATH:-}" ]; then
      if [ -x "$BINIT_PATH" ]; then :; else chmod +x "$BINIT_PATH"; fi
      . "$BINIT_PATH"
    else
      printf "direnv: binit not found at %s\n" "''${BINIT_PATH}" >&2
    fi

    #> Initialize yazi
    YAZI_INIT="$DOTS/Configuration/yazi/init.sh"
    if [ -f "$YAZI_INIT" ]; then
      . "$YAZI_INIT"
    else
      printf "yazi: init.sh not found at %s\n" "$YAZI_INIT" >&2
    fi

    #> Use starship for prompt
    if command -v starship >/dev/null 2>&1; then
      STARSHIP_CONFIG="$DOTS/Configuration/starship/config.toml"
      export STARSHIP_CONFIG
      eval "$(starship init bash)"
    fi

    #> Display shell information with nitch
    if command -v nitch >/dev/null 2>&1; then
      nitch
    fi

    #> Display repository summary with onefetch if in a git repository
    if [ -d .git ] && command -v onefetch >/dev/null 2>&1; then
      onefetch \
      --no-art \
      --no-title \
      --no-color-palette \
      --disabled-fields 'project' 'description' 'head' 'version' 'created' 'languages' 'dependencies' 'authors' 'commits' 'lines-of-code' 'churn' 'size' 'contributors' 'url' 'license'
    fi
  '';
in
{
  inherit
    description
    packages
    env
    shellHook
    ;
}
