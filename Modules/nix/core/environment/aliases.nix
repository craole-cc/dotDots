{
  config,
  host,
  top,
  lix,
  ...
}: let
  dom = "environment";
  mod = "aliases";
  cfg = config.${top}.resolved.${dom}.${mod};
  dots = host.paths.dots or null;

  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.modules.construction) mkConfig;
  inherit (lix.options.construction) mkEnableOption mkOption;
  inherit (lix.types.combinators) attrsOf;
  inherit (lix.types.primitives) str;

  registry = {
    default =
      {
        #~@ File listing
        ll = "lsd --long --git --almost-all";
        lt = "lsd --tree";
        lr = "lsd --long --git --recursive";
      }
      // optionalAttrs (dots != null) {
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
  };
in
  {
    options.${top}.resolved.${dom}.${mod} = {
      enable = mkEnableOption mod // {default = true;};
      default = mkOption {
        description = "Default shell aliases";
        inherit (registry) default;
        type = attrsOf str;
      };
      extra = mkOption {
        description = "Additional shell aliases";
        default = {};
        type = attrsOf str;
      };
    };
  }
  // mkConfig {
    payload = {
      environment.shellAliases = cfg.default // cfg.extra;
    };
    condition = cfg.enable;
  }
