{
  config,
  lib,
  ...
}: let
  #| Native Imports
  inherit (lib.options) mkOption;

  #| Extended Imports
  inherit (config.DOTS.lib.filesystem) pathof pathsIn;

  #| Module Parts
  top = "DOTS";
  dom = "lib";
  mod = "helpers";
  alt = "dib";

  #| Module Options
  mkSource = mkOption {
    description = "Create a source from a directory";
    example = ''mkSource "path/to/directory"'';
    default = targetDir: let
      home = pathof targetDir;
      inherit ((pathsIn home).perNix) attrs lists;
    in {
      inherit home attrs;
      inherit (lists) names paths;
    };
  };

  mkAppOpts = mkOption {
    description = "Options to pass to an application";
    default = name: attrs: let
      options = builtins.mapAttrsToList (_: optionAttrs: optionAttrs.mkOption optionAttrs) attrs;
    in {
      "${name}" = lib.foldr (options: newOption: options // newOption) {} options;
    };
    # default =
    #   name: attrs: with attrs; {
    #     "${name}" = lib.foldr (options: newOption: options // newOption) { } (
    #       builtins.mapAttrsToList (_: "optionAttrs:optionAttrs.mkOption" optionAttrs) attrs
    #     );
    #   };
  };

  mkHash = mkOption {
    description = "Generate a hashed value with a specified number od charactrs from a string";
    default = num: string: let
      inherit (builtins) hashString substring;
    in
      substring 0 num (hashString "md5" string);
  };

  #| Module Exports
  exports = {inherit mkAppOpts mkHash mkSource;};
in {
  options = {
    ${top}.${dom}.${mod} = exports;
    ${alt} = exports;
  };
}
