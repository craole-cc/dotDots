{
  cfg,
  config,
  lix,
  pkgs,
  resolve,
  ...
}: let
  inherit (lix.modules.construction) mkIf mkLayer mkMerge;
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
    runtimeInputs = with pkgs; [coreutils git openssh];
    text = ''
      root=${escapeShellArg cfg.knowledge.root}
      if [[ -e "$root" ]]; then
        printf 'CCKI destination already exists: %s\nInspect it before using ccki.\n' "$root" >&2
        exit 1
      fi
      mkdir -p "$(dirname "$root")"
      git clone -- ${escapeShellArg cfg.knowledge.repository} "$root"
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
      default = "git@github.com:craole-cc/ccki.git";
      description = "Knowledge repository cloned by the explicitly invoked ccki-setup helper.";
    };
  };
  resolutions = mkMerge [
    {knowledge = mkLayer 1000 (resolved.knowledge or {});}
    (mkIf cfg.knowledge.enable {
      environment.variables = environment;
      extra.packages = [command];
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
