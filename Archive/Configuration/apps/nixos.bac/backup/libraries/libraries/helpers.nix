{ config, lib, ... }:
let
  inherit (dib.filesystem) pathof pathsIn;
in
with dib.helpers;
{
  mkSource = mkOption {
    description = "Create a source from a directory";
    example = ''mkSourceNix "path/to/directory"'';
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

}
