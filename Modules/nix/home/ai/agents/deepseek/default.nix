{
  config,
  inputs,
  system,
  lix,
  user,
  pkgs,
  ...
}: let
  inherit (lix.lists.predicates) isIn;
  inherit (lix.schema.packages) selectedPackages;
  inherit (lix.packages.construction) hiPrio;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.types.primitives) package str port;
  inherit (lix.types.combinators) listOf;
  inherit (lix.strings.transformation) escapeShellArg escapeShellArgs;
  inherit (lix.toolkit.binaries) rust-script;

  dom = "ai";
  sub = "agents";
  mod = "deepseek";
  context = mkContext {inherit config dom sub mod;};
  inherit (context) cfg;
  python = pkgs.python3.withPackages (packages: [packages.python-dotenv]);
  launcher = pkgs.writeShellScriptBin "dsh" ''
    exec ${escapeShellArg (toString rust-script)} ${escapeShellArg (toString ../pi/environment.rs)} \
      ${escapeShellArgs cfg.credentials.sources} -- ${cfg.package}/bin/dsh "$@"
  '';
  desktop = pkgs.writeShellScriptBin "deepseek-desktop" ''
    exec ${python}/bin/python ${./desktop.py} \
      ${pkgs.systemd}/bin/systemctl ${cfg.desktop.browser}/bin/chromium \
      ${toString cfg.desktop.port} "$@"
  '';
  backend = pkgs.writeShellApplication {
    name = "deepseek-web-backend";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      umask 077
      runtime="''${XDG_RUNTIME_DIR:?}/deepseek-web"
      mkdir -p "$runtime"
      chmod 0700 "$runtime"
      exec ${launcher}/bin/dsh web --host 127.0.0.1 --port ${toString cfg.desktop.port} --no-open >"$runtime/startup.log" 2>&1
    '';
  };
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
      home.packages = [cfg.package (hiPrio launcher) desktop];
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
          ExecStart = "${backend}/bin/deepseek-web-backend";
          RuntimeDirectory = "deepseek-web";
          RuntimeDirectoryMode = "0700";
          UMask = "0077";
          StandardOutput = "null";
          StandardError = "journal";
          KillMode = "control-group";
        };
      };
    };
  }
