{
  lib,
  system,
  pkgs,
  ...
}: let
  inherit (lib.lists) optionals;
  inherit (pkgs.stdenv) isLinux;

  #|─────────────────────────────────────────────────────────────────────────────|
  #| Configuration                                                               |
  #|─────────────────────────────────────────────────────────────────────────────|

  config = {
    name = "dots";
    version = "2.0.0";
    cache = ".cache";
    prefix = ".";
  };

  #|─────────────────────────────────────────────────────────────────────────────|
  #| Packages                                                                    |
  #|─────────────────────────────────────────────────────────────────────────────|

  packages = with pkgs;
    [
      bat #? Cat clone with syntax highlighting
      direnv #? Environment management per directory
      eza #? Modern ls replacement
      fd #? Fast find alternative
      gitui #? Git terminal UI
      gnused #? GNU stream editor
      jq #? JSON query processor
      lsd #? LSDeluxe file lister
      mise #? Polyglot version manager
      nitch #? System fetch written in nim
      nix-output-monitor #? Build output monitor
      nixd #? Nix language daemon
      onefetch #? Git repository summary
      ripgrep #? Fast grep alternative
      starship #? Cross-shell prompt
      tokei #? Code statistics tool
      undollar #? Remove leading dollar signs
    ]
    ++ (optionals isLinux [xclip wl-clipboard xsel]); #? Linux clipboard tools

  #|─────────────────────────────────────────────────────────────────────────────|
  #| Shell Configuration                                                         |
  #|─────────────────────────────────────────────────────────────────────────────|
  env = {
    NIX_CONFIG = "experimental-features = nix-command flakes";
    SYSTEM = "$(hostname)";
  };

  shellHook = with config; ''
    #> Determine host info dynamically
    HOSTNAME="$(hostname)"
    HOSTTYPE="${system}"
    export HOSTNAME HOSTTYPE

    #> Ensure DOTS is setand available for use
    DOTS="$(pwd -P)"
    DOTS_LIB_SH="${DOTS_LIB_SH: -"${DOTS}/Libraries/shellscript"}"
    export DOTS DOTS_LIB_SH

    #> Set up cache directory structure
    DOTS_CACHE="''${DOTS_CACHE:-"$DOTS/${cache}"}"
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

    #> Use starship for prompt
    if command -v starship >/dev/null 2>&1; then
      STARSHIP_CONFIG="$DOTS/Configuration/starship/config.toml"
      export STARSHIP_CONFIG
      eval "$(starship init bash)"
    fi

    #> Display repository summary with onefetch if in a git repository
    if [ -d .git ] && command -v onefetch >/dev/null 2>&1; then
      onefetch \
      --no-art \
      --no-title \
      --no-color-palette \
      --nerd-fonts \
      --number-separator comma \
      --disabled-fields 'project' 'description' 'head' 'version' 'created' 'languages' 'dependencies' 'authors' 'contributors' 'url' 'churn' 'license'
    fi

    #> Display shell information with nitch
    if command -v nitch >/dev/null 2>&1; then
      nitch
    fi
  '';
in
  pkgs.mkShell (with config; {
    inherit name packages env shellHook;
  })
