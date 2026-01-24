{
  config,
  lib,
  ...
}: let
  inherit (lib.options) mkOption;
  # inherit (lib.strings) toUpper;
  inherit
    (lib.types)
    # attrs
    either
    str
    path
    ;

  dom = "DOTS";
  mod = "paths";
  cfg = config.${dom}.${mod};
in {
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
    conf = mkOption {
      description = "Path to the dots configuration directory.";
      default = "${cfg.base}/Configuration";
      type = either str path;
    };
    doc = mkOption {
      description = "Path to the dots documentation.";
      default = "${cfg.base}/Documentation";
      type = either str path;
    };
    env = mkOption {
      description = "Path to the dots environment.";
      default = "${cfg.base}/Environment";
      type = either str path;
    };
    lib = mkOption {
      description = "Path to the dots lib directory.";
      default = "${cfg.base}/Libraries";
      type = either str path;
    };
    mod = mkOption {
      description = "Path to the dots modules directory.";
      default = "${cfg.base}/Modules";
      type = either str path;
    };
    hosts = mkOption {
      description = "Path to the hosts configuration directory.";
      default = "${cfg.conf}/hosts";
      type = either str path;
    };
    users = mkOption {
      description = "Path to the users configuration directory.";
      default = "${cfg.conf}/users";
      type = either str path;
    };
    pass = mkOption {
      description = "Path to the password directory.";
      default = "/var/lib/dots/passwords";
      type = either str path;
    };
    # nixos = mkOption {
    #   description = "Path to the nixos configuration.";
    #   default = rec {
    #     base = "${cfg.conf}/nixos";
    #     conf = "${base}/configurations";
    #     hosts = "${conf}/hosts";
    #     users = "${conf}/users";
    #   };
    #   type = attrsOf (either str path);
    # };
    # "${sub}" = mkOption {
    #   description = "Path to the ${sub} nixos configuration.";
    #   default = rec {
    #     base = "${cfg.nixos.hosts}/${sub}";
    #     link = ../.;
    #     core = "${base}/core";
    #     desktop = "${base}/desktop";
    #     libraries = "${base}/libraries";
    #     # options = "${base}/options";
    #     modules = "${base}/modules";
    #     # bin = "${libraries}/bin";
    #     # lib = "${libraries}/nix";
    #     # pathman = "${bin}/utilities/pathman";

    #     # home = {
    #     #   base = "${cfg.base}/home";
    #     #   store = "${cfg.link}/home";
    #     # };
    #     # conf = rec {
    #     #   base = "${cfg.base}/.config";
    #     #   dunst = "${base}/dunst";
    #     #   eww = "${base}/eww";
    #     #   ghostty = "${base}/ghostty";
    #     # };
    #   };
    # };
  };

  # config.environment = {
  #   variables = {
  #     DOTS = cfg.dots;
  #     DOTS_BIN = cfg.dotsBin;
  #     DOTS_CFG = cfg.dotsCFG;
  #     "DOTS_${toUpper sub}" = cfg.${sub}.base;
  #     "DOTS_${toUpper sub}_BIN" = "${cfg.core.${sub}.bin}";
  #   };
  #   shellAliases = {
  #     qbx = ''cd ${cfg.base}'';
  #     dots = ''cd ${cfg.dots}'';
  #     binit =
  #       with cfg.core.${sub};
  #       ''[ -f ${pathman} ] && . ${pathman} --action append --dir ${bin} --dir ${dotsBin}'';
  #   };
  #   shellInit =
  #     with cfg.core.${sub};
  #     ''[ -f ${pathman} ] && . ${pathman} --action append --dir ${bin} --dir ${dotsBin}'';
  # };
}
