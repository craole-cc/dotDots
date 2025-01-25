{
  config,
  lib,
  ...
}:
let
  inherit (lib.options) mkOption;
  inherit (lib.types) attrs;

  top = "dots";
  mod = "paths";
  cfg = config.${top}.${mod};
in
{
  options.${top}.${mod} = mkOption {
    description = "Paths related to the dots configuration.";
    default = {
      base = "/home/craole/Configuration";
      store = ../../.;
      core = rec {
        base = "${cfg.base}/core";
        store = "${cfg.store}/core";
        libraries = "${base}/libraries";
        options = "${base}/options";
        modules = "${base}/modules";
        bin = "${libraries}/bin";
        lib = "${libraries}/nix";
        pathman = "${bin}/utilities/pathman";
      };
      home = {
        base = "${cfg.base}/home";
        store = "${cfg.store}/home";
      };
      conf = rec {
        base = "${cfg.base}/.config";
        dunst = "${base}/dunst";
        eww = "${base}/eww";
        ghostty = "${base}/ghostty";
      };
    };
    type = attrs;
  };

  config.environment = {
    variables = {
      DOTS = cfg.base;
      DOTS_CONF = cfg.conf.base;
      DOTS_BIN = cfg.core.bin;
    };
    shellInit = with cfg.core; ''[ -f ${pathman} ] && . ${pathman} --action append --dir ${bin}'';
  };
}
