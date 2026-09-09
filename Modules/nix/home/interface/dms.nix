{
  apps,
  config,
  lib,
  lix,
  pkgs,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "interface";
    sub = "panels";
    mod = "dms-shell";
  };
  inherit (context) cfg ctx;

  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable ({inherit context;} // ctx.wantsDmsShell);
    };
    outputs = {
      programs.dank-material-shell = {
        enable = cfg.enable;

        # The flake module is still used for Home Manager integration, but its
        # pinned package closure is expensive to rebuild locally. Victus tracks
        # nixos-unstable, where both packages are available from nixpkgs and can
        # normally be substituted from cache.nixos.org.
        package = pkgs.dms-shell;
        quickshell.package = pkgs.quickshell;
      };

      # DMS is systemd-managed and resolves its terminal command from the user
      # environment. Keep the value tied to the applications API so DMS and the
      # rest of dotDots cannot drift apart again.
      home.file.".config/environment.d/90-dms.conf".text = ''
        TERMINAL=${apps.terminal.primary.command}
      '';

      # nvidiaGpuMonitor is not part of the declared plugin set. Old manual
      # installs leave an invalid manifest behind and DMS reports it on every
      # startup, so remove only that known stale plugin directory.
      home.activation.removeStaleDmsNvidiaGpuMonitor = lib.hm.dag.entryAfter ["writeBoundary"] ''
        stale="$HOME/.config/DankMaterialShell/plugins/nvidiaGpuMonitor"
        if [ -e "$stale" ] || [ -L "$stale" ]; then
          rm -rf "$stale"
        fi
      '';
    };
  }
