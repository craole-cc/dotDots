{
  cfg,
  config,
  lix,
  pkgs,
  resolve,
  ...
}: let
  inherit (lix.modules.construction) mkIf mkLayer mkMerge mkOverride;
  inherit (lix.options.construction) mkFalse mkOption;
  inherit (lix.types.primitives) str;
  inherit (lix.strings.transformation) escapeShellArg;

  # Command-only snapshot from craole-cc/ccki at
  # b64cb6448bb5b0a71e16d89860f14b554ac988bb. Knowledge data stays external.
  # SHA256: VgwPhcv37NQyaSGxjkQP5dhttIq6V4YxcCJiWvehxy8=
  source = ./run.sh;
  executable = pkgs.runCommand "ccki-run.sh" {} ''
    cp ${source} "$out"
    chmod +x "$out"
    substituteInPlace "$out" --replace-fail '#!/usr/bin/env bash' '#!${pkgs.bash}/bin/bash'
  '';
  environment = {
    CCKI = cfg.knowledge.root;
    CCKI_COMMAND = "ccki";
  };
  command = pkgs.writeShellApplication {
    name = "ccki";
    runtimeInputs = with pkgs; [bash coreutils findutils gawk gnugrep gnused git openssh util-linux];
    text = ''
      default_root=${escapeShellArg cfg.knowledge.root}
      export CCKI="''${CCKI:-$default_root}"
      export CCKI_COMMAND=ccki
      exec bash ${executable} "$@"
    '';
  };
  setup = pkgs.writeShellApplication {
    name = "ccki-setup";
    runtimeInputs = with pkgs; [coreutils git openssh gh];
    text = ''
      root=${escapeShellArg cfg.knowledge.root}
      repository=${escapeShellArg cfg.knowledge.repository}
      if [[ -e "$root" ]]; then
        actual_root="$(git -C "$root" rev-parse --show-toplevel 2>/dev/null)" || {
          printf 'CCKI destination exists but is not a Git checkout.\n' >&2
          exit 1
        }
        if [[ "$(realpath "$actual_root")" != "$(realpath "$root")" ]] ||
          [[ "$(git -C "$root" remote get-url origin)" != "$repository" ]]; then
          printf 'CCKI checkout root or origin does not match configuration.\n' >&2
          exit 1
        fi
      else
        mkdir -p "$(dirname "$root")"
        if [[ "$repository" == https://github.com/* ]]; then
          gh repo clone "$repository" "$root"
        else
          git clone -- "$repository" "$root"
        fi
      fi
      if [[ "$repository" == https://github.com/* ]]; then
        git -C "$root" config --local --replace-all credential.https://github.com.helper ""
        git -C "$root" config --local --add credential.https://github.com.helper '!${pkgs.gh}/bin/gh auth git-credential'
      fi
      printf 'CCKI checkout ready: %s\nRun ccki rules and ccki index --full.\n' "$root"
    '';
  };
  resolved = resolve {};
in {
  options.knowledge = {
    enable = mkFalse "Install CCKI knowledge management and configure Hermes profiles.";
    root = mkOption {
      type = str;
      default = "${dirOf cfg.home.path}/ccki";
      description = "Absolute writable CCKI Git checkout, outside the Nix store and dotfiles repository.";
    };
    repository = mkOption {
      type = str;
      default = "https://github.com/craole-cc/ccki.git";
      description = "Knowledge repository cloned by the explicitly invoked ccki-setup helper.";
    };
  };
  resolutions = mkMerge [
    {knowledge = mkLayer 1000 (resolved.knowledge or {});}
    (mkIf cfg.knowledge.enable {
      environment.variables = environment;
      extra.packages = mkOverride 1000 [command];
      shared.skills.enable = true;
    })
  ];
  outputs = mkIf cfg.knowledge.enable {
    assertions = [
      {
        assertion =
          lix.strings.predicates.hasPrefix "/" cfg.knowledge.root
          && !(lix.strings.predicates.hasPrefix "/nix/store/" cfg.knowledge.root)
          && cfg.knowledge.root != config.home.homeDirectory;
        message = "CCKI requires an absolute writable repository root outside the Nix store and distinct from HOME.";
      }
    ];
    home.packages = [command setup];
    home.sessionVariables = environment;
  };
}
