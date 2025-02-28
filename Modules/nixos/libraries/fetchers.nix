{
  config,
  lib,
  pkgs,
  ...
}:
let
  #| Native Imports
  inherit (builtins)
    getEnv
    currentTime
    ;
  inherit (pkgs) runCommand;
  inherit (lib.strings)
    fileContents
    ;
  inherit (lib.options) mkOption;
  inherit (lib.types) str;

  #| Extended Imports
  inherit (config) DOTS;

  base = "lib";
  mod = "fetchers";
in
{
  options.DOTS.${base}.${mod} = {
    currentUser = mkOption {
      description = "Get the username of the current user.";
      default =
        let
          viaEnvUSER = getEnv "USER";
          viaUSERNAME = getEnv "USERNAME";
          result = if viaEnvUSER != null then viaEnvUSER else viaUSERNAME;
        in
        result;
      type = str;
    };
    currentTime = mkOption {
      description = ''
        Formatted time
      '';
      default =
        let
          viaDateCommand = fileContents (
            runCommand "date" { } ''
              date "+%Y-%m-%d %H:%M:%S %Z" > $out
            ''
          );
        in
        viaDateCommand;
    };
  };
}
