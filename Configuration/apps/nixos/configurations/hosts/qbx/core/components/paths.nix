{
  config,
  lib,
  ...
}:
let
  inherit (lib.options) mkOption;
  inherit (lib.strings) toUpper;
  inherit (lib.types) attrs;

  dom = "dots";
  mod = "paths";
  sub = "qbx";
  cfg = config.${dom}.${mod};
in
{
  options.${dom}.${mod} = {
    dots = mkOption {
      description = "Path to the dots repository.";
      default = "/home/craole/.dots";
    };
    dotsBin = mkOption {
      description = "Path to the dots bin directory.";
      default = "${cfg.dots}/Bin";
    };
    passwordDir = mkOption {
      description = "Path to the password directory.";
      default = "/var/lib/dots/passwords";
    };
    "${sub}" = mkOption {
      description = "Paths related to the dots configuration.";
      default = {
        base = "${cfg.dots}/Configuration/apps/nixos/configurations/hosts/qbx";
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
    type = attrs;
  };

  config.environment = {
    variables = {
      DOTS = cfg.dots;
      DOTS_BIN = cfg.dotsBin;
      "DOTS_${toUpper sub}" = cfg.${sub}.base;
      "DOTS_${toUpper sub}_BIN" = "${cfg.core.${sub}.bin}";
    };
    shellAliases = {
      qbx = ''cd ${cfg.base}'';
      dots = ''cd ${cfg.dots}'';
      binit =
        with cfg.core.${sub};
        ''[ -f ${pathman} ] && . ${pathman} --action append --dir ${bin} --dir ${dotsBin}'';
    };
    shellInit =
      with cfg.core.${sub};
      ''[ -f ${pathman} ] && . ${pathman} --action append --dir ${bin} --dir ${dotsBin}'';
  };
}
