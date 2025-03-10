{
  config,
  lib,
  pkgs,
  ...
}: let
  #| Native Imports
  inherit (builtins) getEnv;
  inherit (pkgs) runCommand;
  inherit (lib.strings) fileContents;
  inherit (lib.options) mkOption;
  inherit (lib.types) str;

  #| Extended Imports

  #| Module Parts
  dom = "lib";
  mod = "fetchers";

  #| Module Options
  currentUser = mkOption {
    description = "Get the username of the current user.";
    default = let
      viaEnvUSER = getEnv "USER";
      viaUSERNAME = getEnv "USERNAME";
      result =
        if viaEnvUSER != null
        then viaEnvUSER
        else viaUSERNAME;
    in
      result;
    type = str;
  };

  currentTime = mkOption {
    description = ''
      Formatted time
    '';
    default = let
      viaDateCommand = fileContents (
        runCommand "date" {} ''
          date "+%Y-%m-%d %H:%M:%S %Z" > $out
        ''
      );
    in
      viaDateCommand;
  };

  #| Module Exports
  exports = {
    inherit
      currentUser
      currentTime
      ;
  };
in {
  options = {
    DOTS.${dom}.${mod} = exports;
    dib = exports;
  };
}
