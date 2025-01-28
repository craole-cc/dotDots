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
  dom = "dots";
  mod = "paths";
  cfg = config.${dom}.${mod};
in
{
  options.${dom}.${mod} = {
    qbx = mkOption {
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
  };

  config.environment = {
    variables = {
      DOTS = dots;
      DOTS_BIN = dotsBin;
      QBX = cfg.base;
      QBX_BIN = "${cfg.core.bin}";
    };
    shellAliases = {
      qbx = ''cd ${cfg.base}'';
      dots = ''cd ${dots}'';
      binit =
        with cfg.core;
        ''[ -f ${pathman} ] && . ${pathman} --action append --dir ${bin} --dir ${dotsBin}'';
    };
    shellInit =
      with cfg.core;
      ''[ -f ${pathman} ] && . ${pathman} --action append --dir ${bin} --dir ${dotsBin}'';
  };
}
