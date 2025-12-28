{
  host,
  pkgs,
  lib,
  lix,
  inputs,
  ...
}: let
  inherit (host.paths) dots;
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.modules) mkIf;
  inherit (lix.applications.resolution) editors browsers terminals launchers bars;
  inherit (lix.lists.predicates) isIn;

  user = host.users.data.primary;
  apps = user.applications or {};
  system = pkgs.stdenv.hostPlatform.system;

  # Use the packages from specialArgs.inputs
  resolvedInputs = inputs.packages or {};

  # Get all packages with resolved inputs and system
  editorPkgs = editors.packages {
    inherit pkgs system;
    inputs = resolvedInputs;
    editorConfig = apps.editor or {};
  };

  browserPkgs = browsers.packages {
    inherit pkgs system;
    inputs = resolvedInputs;
    appConfig = apps.browser or {};
  };

  terminalPkgs = terminals.packages {
    inherit pkgs system;
    inputs = resolvedInputs;
    appConfig = apps.terminal or {};
  };

  launcherPkgs = launchers.packages {
    inherit pkgs system;
    inputs = resolvedInputs;
    appConfig = apps.launcher or {};
  };

  barPkgs = bars.packages {
    inherit pkgs system;
    inputs = resolvedInputs;
    appConfig = apps.bar or {};
  };

  # Get commands with resolved inputs and system
  editorCmds = editors.commands {
    inherit pkgs system;
    inputs = resolvedInputs;
    editorConfig = apps.editor or {};
  };

  browserCmds = browsers.commands {
    inherit pkgs system;
    inputs = resolvedInputs;
    appConfig = apps.browser or {};
  };

  terminalCmds = terminals.commands {
    inherit pkgs system;
    inputs = resolvedInputs;
    appConfig = apps.terminal or {};
  };

  launcherCmds = launchers.commands {
    inherit pkgs system;
    inputs = resolvedInputs;
    appConfig = apps.launcher or {};
  };

  barCmds = bars.commands {
    inherit pkgs system;
    inputs = resolvedInputs;
    appConfig = apps.bar or {};
  };
in {
  environment = {
    systemPackages =
      editorPkgs
      ++ browserPkgs
      ++ terminalPkgs
      ++ launcherPkgs
      ++ barPkgs;

    shellAliases = {
      ll = "lsd --long --git --almost-all";
      lt = "lsd --tree";
      lr = "lsd --long --git --recursive";
      edit-dots = "$EDITOR ${dots}";
      ide-dots = "$VISUAL ${dots}";
      push-dots = "gitui --directory ${dots}";
      repl-host = "nix repl ${dots}#nixosConfigurations.$(hostname)";
      repl-dots = "nix repl ${dots}#repl";
      switch-dots = "sudo nixos-rebuild switch --flake ${dots}";
      nxs = "push-dots; switch-dots";
      nxu = "push-dots; switch-dots; topgrade";
    };

    sessionVariables =
      {
        DOTS = dots;
        EDITOR = editorCmds.editor;
        VISUAL = editorCmds.visual;
        BROWSER = browserCmds.primary;
        TERMINAL = terminalCmds.primary;
        LAUNCHER = launcherCmds.primary;
        BAR = barCmds.primary;
      }
      // (
        optionalAttrs (host.interface.displayProtocol or "wayland" == "wayland") {
          #? For Clutter/GTK apps
          CLUTTER_BACKEND = "wayland";

          #? For GTK apps
          GDK_BACKEND = "wayland";

          #? Required for Java UI apps on Wayland
          _JAVA_AWT_WM_NONREPARENTING = "1";

          #? Enable Firefox native Wayland backend
          MOZ_ENABLE_WAYLAND = "1";

          #? Force Chromium/Electron apps to use Wayland
          NIXOS_OZONE_WL = "1";

          #? Qt apps use Wayland
          QT_QPA_PLATFORM = "wayland";

          #? Disable client-side decorations for Qt apps
          QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

          #? Auto scale for HiDPI displays
          QT_AUTO_SCREEN_SCALE_FACTOR = "1";

          #? SDL2 apps Wayland backend
          SDL_VIDEODRIVER = "wayland";

          #? Allow software rendering fallback on Nvidia/VM
          WLR_RENDERER_ALLOW_SOFTWARE = "1";

          #? Disable hardware cursors on Nvidia/VM
          WLR_NO_HARDWARE_CURSORS = "1";

          #? Indicate Wayland session to apps
          XDG_SESSION_TYPE = "wayland";
        }
      );
  };

  programs = {
    git = {
      enable = true;
      lfs.enable = true;
      prompt.enable = true;
    };

    obs-studio = {
      enable = isIn ["video" "webcam"] (host.functionalities or []);
      enableVirtualCamera = true;
    };
  };
}
