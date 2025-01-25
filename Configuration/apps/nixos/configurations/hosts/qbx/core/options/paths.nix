{
  config,
  lib,
  ...
}:
let
  inherit (lib.options) mkOption;
  inherit (lib.types) attrs;

  dots = "/home/craole/.dots";
  dotsBin = "${dots}/Bin";
  top = "paths";
  mod = "qbx";
  cfg = config.dots.${top}.${mod};
in
{
  options.dots.${top}.${mod} = mkOption {
    description = "Paths related to the dots configuration.";
    default = {
      base = "${dots}/Configuration/apps/nixos/configurations/hosts/qbx";
      link = ../../.;
      core = rec {
        base = "${cfg.base}/core";
        store = "${cfg.link}/core";
        libraries = "${base}/libraries";
        options = "${base}/options";
        modules = "${base}/modules";
        bin = "${libraries}/bin";
        lib = "${libraries}/nix";
        pathman = "${bin}/utilities/pathman";
      };
      home = {
        base = "${cfg.base}/home";
        store = "${cfg.link}/home";
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
      DOTS_BIN = dotsBin;
      QBX_BIN = "${cfg.core.bin}";
    };
    shellInit =
      with cfg.core;
      ''[ -f ${pathman} ] && . ${pathman} --action append --dir ${bin} --dir ${dotsBin}'';
  };
}
