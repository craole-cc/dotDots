{
  dib,
  lib,
  pkgs,
  ...
}:
let
  #| Internal Imports

  #| External Libraries
  inherit (builtins) getEnv;
  inherit (pkgs) fetchurl runCommand;
  inherit (lib.attrsets) hasAttr;
  inherit (lib.misc) fakeHash;
  inherit (lib.options) mkOption;
  inherit (lib.strings) fileContents fromJSON floatToString;
  inherit (lib.types) str attrs;

  #| Extended
  mod = "fetchers";

  inherit (dib.lists)
    prep
    clean
    infixed
    suffixed
    ;
  inherit (dib.filesystem) nullOrPathOf;
in
with dib."${mod}";
{
  /**
    "Get the hostname of the current machine."
  */
  hostname = runCommand "get-hostname" { } ''
    echo "$(hostname)" > $out
  '';

  /**
    "Get the username of the current user."
  */
  username = getEnv "USER";

  /**
    Retrieve a github email for the specified user via the GitHub API

    Parameters:
      user = User to retrieve email for
      hash = Hash of the user's public key

    Returns: email

    Examples:
      githubEmail {
        user = "gituser";
        hash = "sha256-+0EbIkNUM3UvTEa/RlkjcSeizuHJfEa3RNwpbh+XwnE=";
      }

      githubEmail { user = "gituser"; }
  */
  githubEmail =
    {
      user,
      hash ? fakeHash,
    }:
    let
      # Function to fetch user data from GitHub API
      fetchData =
        login: hash:
        let
          fetchedData = nullOrPathOf (fetchurl {
            url = "https://api.github.com/users/${login}";
            sha256 = hash;
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
    getEmail (parseData (fetchData user hash));

  tests =
    let
      assertions = {
        githubEmail = [
          "Craole => ${
            githubEmail {
              user = "Craole";
              hash = "sha256-PZ7xOLJPApOqIIduh093NlK/yW75nwFFH0bVIEqd5JI=";
            }
          }"
          "craole-cc => ${
            githubEmail {
              user = "craole-cc";
              hash = "sha256-ZiWTR4QNgXDcRFMpTQ5//VKg7bQINAOYirtWB57kk+w=";
            }
          }"
          "Qyatt876 => ${
            githubEmail {
              user = "Qyatt876";
              hash = "sha256-plUm2biUi9u9b+5680u2ItAPPGYzuekdjQPYVpdgXuI=";
            }
          }"
        ];
      };
    in
    {
      inherit (assertions) githubEmail;
    };

}
