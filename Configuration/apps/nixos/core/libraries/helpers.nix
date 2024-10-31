{ config, lib, ... }:
let
  inherit (config.DOTS) Libraries;
  inherit (Libraries.filesystem) pathOf pathsIn;

  mod = "helpers";
  # cfg = Libraries.${mod};

  #| External libraries
  inherit (lib.options) mkOption;
in
{
  options.DOTS.Libraries.${mod} = {
    mkSource = mkOption {
      description = "Create a source from a directory";
      example = ''mkSourceNix "path/to/directory"'';
      default =
        _home:
        let
          home = pathOf _home;
          inherit ((pathsIn home).perNix) attrs lists;
        in
        {
          inherit home attrs;
          inherit (lists) names paths;
        };
    };

    mkAppOptions = mkOption {
      description = "Options to pass to an application";
      default =
        name: attrs:
        let
          options = builtins.mapAttrsToList (_: optionAttrs: optionAttrs.mkOption optionAttrs) attrs;
        in
        {
          "${name}" = lib.foldr (options: newOption: options // newOption) { } options;
        };
    };

    # mkAppOptions = mkOption {
    #   description="Options to pass to an application";
    #   default = name: attrs: with attrs; { "${name}" =lib.foldr(options: newOption: options//newOption) {} (builtins.mapAttrsToList (_: optionAttrs:optionAttrs.mkOption optionAttrs)attrs); };
    # }
  };
}
