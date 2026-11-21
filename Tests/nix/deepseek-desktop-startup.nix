{flake}: let
  pkgs = flake.inputs.nixPackages.legacyPackages.x86_64-linux;
  config =
    (flake.nixosConfigurations.Victus.extendModules {
      modules = [
        {
          home-manager.users.craole._.resolved.ai.agents.deepseek.defined = {
            package = pkgs.writeShellScriptBin "dsh" "echo synthetic-backend";
            credentials.sources = [];
          };
        }
      ];
    }).config;
  command = pkgs.lib.escapeShellArgs (pkgs.lib.toList config.home-manager.users.craole.systemd.user.services.deepseek-web.Service.ExecStart);
in
  pkgs.runCommand "deepseek-desktop-startup-check" {} ''
    export XDG_RUNTIME_DIR=$TMPDIR/fresh-runtime
    mkdir -p "$XDG_RUNTIME_DIR"
    ${command}
    test -s "$XDG_RUNTIME_DIR/deepseek-web/startup.log"
    test "$(stat -c %a "$XDG_RUNTIME_DIR/deepseek-web")" = 700
    test "$(stat -c %a "$XDG_RUNTIME_DIR/deepseek-web/startup.log")" = 600
    grep -q synthetic-backend "$XDG_RUNTIME_DIR/deepseek-web/startup.log"
    touch "$out"
  ''
