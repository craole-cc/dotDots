{
  config,
  lib,
  pkgs,
  ...
}:
let
  #| Internal Imports
  inherit (config.DOTS) Libraries;
  inherit (Libraries.filesystem) nullOrpathof;

  mod = "fetchers";
  cfg = Libraries.${mod};

  #| External Libraries
  inherit (builtins) getEnv;
  inherit (pkgs) fetchurl;
  inherit (lib.attrsets) hasAttr;
  inherit (lib.options) mkOption;
  inherit (lib.strings) fileContents fromJSON floatToString;
  inherit (lib.types) str attrs;
in
{
  options.DOTS.Libraries.${mod} = {

    host = {
      name = mkOption {
        description = "The current hostname";
        default = config.networking.hostName;
        type = str;
      };

      # dots = mkOption {
      #   description = "The DOTS config of the current host";
      #   default = with cfg.host; if hasAttr name hosts then hosts.${name} else { };
      #   type = attrs;
      # };
    };

    user = {
      name = mkOption {
        description = "The current hostname";
        default = getEnv "USER";
        type = str;
      };

      # dots = mkOption {
      #   description = "The DOTS config of the current host";
      #   default = with cfg.user; if hasAttr name users then users.${name} else { };
      #   type = attrs;
      # };
    };

    githubEmail = mkOption {
      description = "Retrieve a github email for the specified user via the GitHub API";
      default =
        {
          user,
          sha256 ? "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
        }:
        let

          # Function to fetch user data from GitHub API
          fetchData =
            login: sha256:
            let
              fetchedData = nullOrpathof (fetchurl {
                url = "https://api.github.com/users/${login}";
                inherit sha256;
              });
            in
            if fetchedData != null then fetchedData else throw "Unable to retrieve the requested data";

          # Read the contents of the file
          parseData =
            file:
            let
              data = fromJSON (fileContents file);
            in
            if data ? login then data else throw "The 'login' field is missing in the JSON data";

          # Extract/build the email from JSON data
          getEmail =
            data:
            if data.email != null then
              data.email
            else
              "${floatToString data.id}+${data.login}@users.noreply.github.com";
        in
        getEmail (parseData (fetchData user sha256));
    };

    test = with cfg; {
      githubEmail = mkOption {
        default = githubEmail {
          user = "Craole";
          sha256 = "oFenbLVTcrFm5mLvo4XNeCfmTTTO7dv7nqdr+0VSfFA=";
        };
      };
    };
  };
}
