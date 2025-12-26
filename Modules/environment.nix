{
  host,
  pkgs,
  lix,
  ...
}: let
  inherit (host.paths) dots;
  inherit (lix.applications.common) editors browsers terminals launchers bars;

  user = host.users.data.primary;
  apps = user.applications;

  # Get all packages
  editorPkgs = editors.packages {
    inherit pkgs;
    editorConfig = apps.editor or {};
  };

  browserPkgs = browsers.packages {
    inherit pkgs;
    appConfig = apps.browser or {};
  };

  terminalPkgs = terminals.packages {
    inherit pkgs;
    appConfig = apps.terminal or {};
  };

  launcherPkgs = launchers.packages {
    inherit pkgs;
    appConfig = apps.launcher or {};
  };

  barPkgs = bars.packages {
    inherit pkgs;
    appConfig = apps.bar or {};
  };

  # Get commands
  editorCmds = editors.commands {
    inherit pkgs;
    editorConfig = apps.editor or {};
  };

  browserCmds = browsers.commands {
    inherit pkgs;
    appConfig = apps.browser or {};
  };

  terminalCmds = terminals.commands {
    inherit pkgs;
    appConfig = apps.terminal or {};
  };

  launcherCmds = launchers.commands {
    inherit pkgs;
    appConfig = apps.launcher or {};
  };

  barCmds = bars.commands {
    inherit pkgs;
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
}
