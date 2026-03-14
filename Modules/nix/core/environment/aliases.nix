{
  config,
  host,
  lib,
  top,
  ...
}: let
  dom = "environment";
  mod = "aliases";
  cfg = config.${top}.${dom}.${mod};

  # user = host.users.data.primary or {};
  dots = host.paths.dots or null;

  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) attrsOf str;

  defaultAliases =
    {
      #~@ File listing
      ll = "lsd --long --git --almost-all";
      lt = "lsd --tree";
      lr = "lsd --long --git --recursive";
    }
    // lib.optionalAttrs (dots != null) {
      #~@ Dotfiles management
      edit-dots = "$EDITOR ${dots}";
      ide-dots = "$VISUAL ${dots}";
      push-dots = "gitui --directory ${dots}";

      #~@ Nix REPL
      repl-host = "nix repl ${dots}#nixosConfigurations.$(hostname)";
      repl-dots = "nix repl ${dots}#repl";

      #~@ Rebuild shortcuts
      switch-dots = "sudo nixos-rebuild switch --flake ${dots}";
      nxs = "push-dots; switch-dots";
      nxu = "push-dots; switch-dots; topgrade";
    };
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = true;};
    base = mkOption {
      description = "Base shell aliases";
      default = defaultAliases;
      type = attrsOf str;
    };
    extra = mkOption {
      description = "Additional shell aliases";
      default = {};
      type = attrsOf str;
    };
  };

  config = mkIf cfg.enable {
    environment.shellAliases = cfg.base // cfg.extra;
  };
}
