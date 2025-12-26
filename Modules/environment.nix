{
  host,
  pkgs,
  lix,
  ...
}: let
  inherit (host.paths) dots;
  inherit (lix.applications.editors) packages commands;

  editorConfig = host.users.data.primary.applications.editor or {};

  editorPkgs = packages {inherit pkgs editorConfig;};
  editorCmds = commands {inherit pkgs editorConfig;};
in {
  environment = {
    systemPackages = editorPkgs;

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
    };
  };
}
