{lix, ...}: let
  inherit (lix.attrsets) attrNames;
  inherit (lix.debug) requireThat;
  inherit (lix.lists) elem filter head;
  inherit (lix.strings) toLower concatStringsSep;

  aliases = {
    administrator = ["administrator" "admin" "root" "superuser" "sudo"];
    user = ["user" "standard" "member" "normal"];
    guest = ["guest" "temporary" "temp" "ephemeral"];
    service = ["service" "system" "application" "app" "daemon"];
  };

  default = "user";

  resolve = {
    args ? {},
    role ? args.role or default,
    name ? args.name or null,
    context ? "resolve user role (user \"${toString name}\")",
  }: let
    roles = attrNames aliases;
    lower = toLower (toString role);
    matches = filter (canonical: elem lower aliases.${canonical}) roles;
  in
    assert requireThat {
      inherit context;
      condition = matches != [];
      message = "unknown role '${
        toString role
      }' (expected one of: ${
        concatStringsSep ", " roles
      }, or a recognized alias)";
    };
      head matches;
in {inherit default resolve;}
