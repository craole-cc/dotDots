{
  config,
  inputs,
  system,
  lix,
  user,
  pkgs,
  lib,
  ...
}: let
  inherit (lix.lists.predicates) isIn;
  inherit (lix.schema.packages) selectedPackages;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.types.primitives) package str;
  inherit (lix.types.combinators) listOf;
  inherit (lix.strings.transformation) escapeShellArgs;

  dom = "ai";
  sub = "agents";
  mod = "deepseek";
  context = mkContext {inherit config dom sub mod;};
  inherit (context) cfg;
  python = pkgs.python3.withPackages (packages: [packages.python-dotenv]);
  launcher = pkgs.writeShellScriptBin "dsh" ''
    exec ${python}/bin/python ${../pi/environment.py} \
      ${escapeShellArgs cfg.credentials.sources} -- ${cfg.package}/bin/dsh "$@"
  '';
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        inherit context;
        condition = isIn ["deepseek" "deepseek-harness" "dsh" "dhs"] (selectedPackages user);
      };
      package = mkOption {
        type = package;
        default = inputs.llm-agents.packages.${system}.dsh;
        description = "DeepSeek Harness package exposed in the user's profile.";
      };
      credentials.sources = mkOption {
        type = listOf str;
        default = let
          private = "${config.home.homeDirectory}/Private";
          configHome = config.xdg.configHome;
        in [
          "${private}/deepseek.env"
          "${private}/deepseek/.env"
          "${private}/deepseek/*.env"
          "${private}/dsh.env"
          "${private}/dsh/.env"
          "${private}/dsh/*.env"
          "${configHome}/dsh/.env"
          "${configHome}/dsh/*.env"
        ];
        description = "Ordered runtime dotenv paths or glob patterns for DeepSeek Harness. Later files override earlier values; glob matches are sorted and missing files are skipped. Credentials stay outside the Nix store.";
      };
    };
    outputs.home.packages = [cfg.package (lib.hiPrio launcher)];
  }
