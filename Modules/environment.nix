{
  host,
  pkgs,
  ...
}: let
  inherit (host.paths) dots;
in {
  environment = {
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
      EDITOR = "hx"; #TODO: Take this from the primary user
      VISUAL = "code"; #TODO: Take this from the primary user
    };
    systemPackages = with pkgs; [
      #~@ Development
      helix
      vim
      nil
      nixd
      nixfmt
      alejandra
      rust-script
      rustfmt
      gcc
      shfmt
      shellcheck

      #~@ Tools
      cowsay
      gitui
      lm_sensors
      lsd
      lshw
      mesa-demos
      topgrade
      toybox
      speedtest-cli
      speedtest-go
    ];
  };
}
