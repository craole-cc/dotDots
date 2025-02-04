{
  config,
  lib,
  ...
}:
let
  inherit (lib.options) mkOption;
  inherit (lib.strings) toUpper;
  inherit (lib.types)
    attrs
    either
    str
    path
    ;

  dom = "dots";
  mod = "paths";
  sub = "qbx";
  cfg = config.${dom}.${mod};
in
{
  options.${dom}.${mod} = {
    base = mkOption {
      description = "Path to the dots repository.";
      default = "/home/craole/.dots";
      type = either str path;
    };
    bin = mkOption {
      description = "Path to the dots bin directory.";
      default = "${cfg.base}/Bin";
      type = either str path;
    };
    cfg = mkOption {
      description = "Path to the dots configuration.";
      default = "${cfg.base}/Configuration";
      type = either str path;
    };
    pass = mkOption {
      description = "Path to the password directory.";
      default = "/var/lib/dots/passwords";
      type = either str path;
    };
    "${sub}" = mkOption {
      description = "Paths related to the dots configuration.";
      default = {
        base = "${cfg.dots}/Config/apps/nixos/configurations/hosts/qbx";
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
      DOTS = cfg.dots;
      DOTS_BIN = cfg.dotsBin;
      DOTS_CFG = cfg.dotsCFG;
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
