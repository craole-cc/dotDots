{
  user,
  lix,
  lib,
  config,
  src,
  top,
  ...
}: let
  inherit (lix.modules.core.staging) mkStaged;
  name = "niri";
  inherit (lib.modules) mkIf;
  inherit (lix.attrsets.predicates) waylandEnabled;

  isAllowed =
    waylandEnabled {
      inherit config;
      interface = user.interface or {};
    }
    && (user.interface.windowManager or null) == name;
  payload = {
    xdg.configFile."niri/config.kdl" = mkIf (src != null) {
      source = src + "/Configuration/niri/default.kdl";
    };

    programs = {
      # ${app} = #TODO: Niri flake is outdated
      #   {enable = true;}
      #   // import ./bindings.nix
      #   // import ./layout.nix
      #   // import ./settings.nix;

      # niriswitcher = import ./switcher {inherit user;};
    };
  };
in {
  # options.programs.niriswitcher = mkOption {
  #   default = {};
  #   type = submodule {
  #     options.enable = mkEnableOption "niriswitcher";
  #     freeformType = attrsOf anything;
  #   };
  # };

  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = isAllowed;
  });
}
