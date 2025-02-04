{ config, lib, ... }:
let
  #| Native Imports
  inherit (lib.options) mkOption;

  #| Extended Imports
  inherit (config) DOTS;
  base = "lib";
  mod = "helpers";

  inherit (DOTS.lib.filesystem) pathof pathsIn;
in
{
  options.DOTS.${base}.${mod} = {
    makeSource = mkOption {
      description = "Create a source from a directory";
      example = ''mkSource "path/to/directory"'';
      default =
        _home:
        let
          home = pathof _home;
          inherit ((pathsIn home).perNix) attrs lists;
        in
        {
          inherit home attrs;
          inherit (lists) names paths;
        };
    };

    makeAppOptions = mkOption {
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
