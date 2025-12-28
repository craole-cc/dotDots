{
  host,
  pkgs,
  lib,
  lix,
  inputs,
  ...
}: let
  inherit (host.paths) dots;
  inherit (lix.applications.resolution) editors browsers terminals launchers bars;
  inherit (lib.modules) mkIf;
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

    sessionVariables = {
      DOTS = dots;
      EDITOR = editorCmds.editor;
      VISUAL = editorCmds.visual;
      BROWSER = browserCmds.primary;
      TERMINAL = terminalCmds.primary;
      LAUNCHER = launcherCmds.primary;
      BAR = barCmds.primary;
    };
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
