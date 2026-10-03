{lix, ...}: let
  inherit (lix.attrsets) attrNames;
  inherit (lix.debug) requireThat;
  inherit (lix.lists) any elem head filter;
  inherit (lix.strings) toLower concatStringsSep;
  inherit (lix.trivial) isNotEmpty;

  default = [];

  aliases = {
    administrator = ["administrator" "admin" "root" "superuser" "sudo"];
    user = ["user" "standard" "member" "normal"];
    guest = ["guest" "temporary" "temp" "ephemeral"];
    service = ["service" "system" "application" "app" "daemon"];
  };

  normalizeRole = {
    role,
    context,
  }: let
    roles = attrNames aliases;
    lower = toLower (toString role);
    matches =
      filter
      (canonical: elem lower aliases.${canonical})
      roles;
  in
    assert requireThat {
      inherit context;
      condition = matches != [];
      message = "unknown principal role '${
        toString role
      }' (expected one of: ${
        concatStringsSep ", " roles
      }, or a recognized alias)";
    };
      head matches;

  normalize = context: principal:
    principal
    // {
      role = normalizeRole {
        inherit context;
        role = principal.role or "user";
      };
      enable = principal.enable or true;
      autoLogin = principal.autoLogin or false;
    };

  resolve = {
    principals ? args.principals or [],
    name ? args.name or null,
    context ? "resolve host principals (host \"${toString name}\")",
    ...
  } @ args: let
    normalized = map (normalize context) principals;
    hasEnabledAdmin = any (p: p.role == "administrator" && p.enable) normalized;
  in
    assert requireThat {
      inherit context;
      condition = isNotEmpty normalized;
      message = "must declare at least one principal";
    };
    assert requireThat {
      inherit context;
      condition = hasEnabledAdmin;
      message = "must declare at least one enabled principal with an administrator role";
    }; normalized;
in {inherit default resolve;}
