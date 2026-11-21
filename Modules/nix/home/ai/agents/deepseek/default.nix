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
  inherit (lix.types.primitives) package str port;
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
  desktop = pkgs.writeShellScriptBin "deepseek-desktop" ''
    exec ${python}/bin/python ${./desktop.py} \
      ${pkgs.systemd}/bin/systemctl ${cfg.desktop.browser}/bin/chromium \
      ${toString cfg.desktop.port} "$@"
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
      desktop = {
        browser = mkOption {
          type = package;
          default = pkgs.chromium;
          description = "Chromium package used for the dedicated DeepSeek app window.";
        };
        port = mkOption {
          type = port;
          default = 3081;
          description = "Loopback port for the on-demand DeepSeek desktop Web service.";
        };
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
    outputs = {
      home.packages = [cfg.package (lib.hiPrio launcher) desktop];
      xdg.desktopEntries.deepseek-harness = {
        name = "DeepSeek Harness";
        comment = "Open the DeepSeek Harness workspace";
        exec = "${desktop}/bin/deepseek-desktop";
        icon = "applications-development";
        terminal = false;
        categories = ["Development" "Utility"];
        settings.StartupWMClass = "deepseek-harness";
      };
      systemd.user.services.deepseek-web = {
        Unit.Description = "DeepSeek Harness desktop Web backend";
        Service = {
          ExecStartPre = "${pkgs.coreutils}/bin/truncate -s 0 %t/deepseek-web/startup.log";
          ExecStart = "${launcher}/bin/dsh web --host 127.0.0.1 --port ${toString cfg.desktop.port} --no-open";
          RuntimeDirectory = "deepseek-web";
          RuntimeDirectoryMode = "0700";
          UMask = "0077";
          StandardOutput = "append:%t/deepseek-web/startup.log";
          StandardError = "append:%t/deepseek-web/startup.log";
          KillMode = "control-group";
        };
      };
    };
  }
