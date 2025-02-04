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
    readFile
    currentTime
    toString
    ;
  inherit (pkgs) fetchurl runCommand;
  inherit (lib.attrsets) hasAttr;
  inherit (lib.misc) fakeHash;
  inherit (lib.strings)
    removeSuffix
    fileContents
    fromJSON
    floatToString
    ;
  inherit (lib.options) mkOption;
  inherit (lib.types) nullOr str attrs;

  #| Extended Imports
  inherit (config) DOTS;

  base = "lib";
  mod = "fetchers";
  cfg = DOTS.${base}.${mod};

  inherit (cfg)
    prep
    prune
    infixed
    suffixed
    ;

  inherit (DOTS.${base}.filesystem) pathOrNull;
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
          viaBuiltin = fileContents (
            runCommand "date" { } ''
              date -d @${toString currentTime} "+%Y-%m-%d %H:%M:%S %Z" > $out
            ''
          );
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
