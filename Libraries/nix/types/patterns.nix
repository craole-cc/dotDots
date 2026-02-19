{lib, ...}: let
  inherit (lib.types) str strMatching;

  # Email-like string
  email = strMatching "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}";

  # URL-like string
  url = strMatching "https?://.*";

  # Semantic version
  semver = strMatching "[0-9]+\\.[0-9]+\\.[0-9]+.*";

  # Git reference (branch, tag, commit)
  gitRef = str;

  # Username (alphanumeric with underscores/hyphens)
  username = strMatching "[a-zA-Z0-9_-]+";

  # Hostname
  hostname = strMatching "[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*";

  # IPv4 address
  ipv4 = strMatching "[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}";

  # Color hex code
  color = strMatching "#[0-9a-fA-F]{6}";

  # UUID
  uuid = strMatching "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}";
in {
  inherit email url semver gitRef username hostname ipv4 color uuid;
  _rootAliases = {
    emailPattern = email;
    urlPattern = url;
    semverPattern = semver;
    gitRefPattern = gitRef;
    usernamePattern = username;
    hostnamePattern = hostname;
    ipv4Pattern = ipv4;
    colorPattern = color;
    uuidPattern = uuid;
  };
}
