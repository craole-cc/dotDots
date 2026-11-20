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
  mod = "pi";

  context = mkContext {inherit config dom sub mod;};
  inherit (context) cfg;
  python = pkgs.python3.withPackages (packages: [packages.python-dotenv]);
  launcher = pkgs.writeShellScriptBin "pi" ''
    exec ${python}/bin/python ${./environment.py} \
      ${escapeShellArgs cfg.credentials.sources} -- ${cfg.package}/bin/pi "$@"
  '';
in
  mkConfig {
    inherit context;

    options = {
      enable = mkEnable {
        inherit context;
        condition = isIn [mod] (selectedPackages user);
      };

      package = mkOption {
        type = package;
        default = inputs.llm-agents.packages.${system}.pi;
        description = "Pi agent harness package to expose in this user's profile.";
      };

      credentials.sources = mkOption {
        type = listOf str;
        default = let
          private = "${config.home.homeDirectory}/Private";
        in [
          "${private}/pi.env"
          "${private}/pi/.env"
          "${private}/pi/*.env"
        ];
        description = "Ordered runtime dotenv paths or glob patterns for Pi. Later files override earlier values; glob matches are sorted and missing files are skipped.";
      };
    };

    outputs.home.packages = [cfg.package (lib.hiPrio launcher)];
  }
