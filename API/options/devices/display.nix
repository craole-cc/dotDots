{lix, ...}: let
  inherit (lix.std.options) mkOption;
  inherit (lix.std.modules) mkDefault;
  inherit (lix.std.types) attrsOf either float int oneOf str submodule;

  displayOpts = {
    config,
    ...
  }: let
    cfg = config;
  in {
    options = {
      resolution = mkOption {
        description = "Display resolution (e.g., 1920x1080) or preferred (auto)";
        default = "preferred";
        type = str;
      };
      refreshRate = mkOption {
        description = "Refresh rate in Hz or preferred (auto)";
        default = "preferred";
        type = oneOf [
          int
          float
          str
        ];
      };
      scale = mkOption {
        description = "Display scale factor";
        default = 1.0;
        type = either float int;
      };
      position = mkOption {
        description = "Display position (e.g., 0x0, 1920x0) or 'auto'";
        type = str;
        default = "auto";
      };
    };

    config = with cfg; {
      refreshRate = mkDefault (
        if refreshRate == null
        then "preferred"
        else refreshRate
      );
      scale = mkDefault (
        if scale == null
        then "preferred"
        else scale
      );
    };
  };
in {
  display = mkOption {
    description = ''
      List of display/monitor configurations
    '';
    default = {};
    example = {
      "HDMI-A-1" = {
        resolution = "1920x1080";
        refreshRate = 75;
        scale = 1;
        position = "0x0";
      };
      "eDP-1" = {
        resolution = "1920x1080";
        refreshRate = 144.15;
        scale = 1;
        position = "auto";
      };
    };
    type = attrsOf (submodule displayOpts);
  };
}
