{_, ...}: let
  inherit (_.lists.generators) mkCaseInsensitiveValidator mkEnum;
  inherit (_.testing.unit) mkTest runTests;

  /**
  User roles - system access and privilege levels.

  Defines user account types and their associated privilege levels.

  # Roles
  - administrator: Full system administrator with unrestricted root access (alias: admin)
  - developer: Developer account with sudo access and development tools (alias: dev)
  - poweruser: Advanced user with elevated privileges for system configuration
  - user: Normal user with limited permissions
  - guest: Temporary user with restricted access and limited permissions
  - service: Service account for automated processes and system daemons

  # Structure
  ```nix
  {
    values = [ "administrator" "developer" "poweruser" ... ];
    validator = { check, list };
  }
  ```

  # Usage
  ```nix
  # Validate user role
  _.enums.user.roles.validator.check { name = "Developer"; }  # => true

  # Check if user has elevated privileges
  _.isAnyInList [config.role] ["administrator" "developer" "poweruser"] true

  # Get all available roles
  _.enums.user.roles.values
  ```
  */
  roles = mkEnum {
    values = ["administrator" "developer" "poweruser" "user" "guest" "service"];
    aliases = {
      admin = "administrator";
      dev = "developer";
    };
  };

  /**
  User capabilities - primary use cases and workflows.

  Defines what the user primarily does with their system.
  Used to configure appropriate applications and optimizations.


  # Creative
  - creation: Art, music, video production
  - multimedia: Media consumption and light editing
  - gaming: Gaming and entertainment

  # Professional
  - development: Software development
  - writing: Documents, notes, content
  - analysis: Data analysis, spreadsheets
  - management: Project/task management
  - conferencing: Video calls, remote meetings

  # System
  - administration: System administration
  - automation: Scripting, task automation

  # Structure
  ```nix
  {
    values = [ "writing" "conferencing" "development" ... ];
    validator = { check, list };
  }
  ```

  # Usage
  ```nix
  # Validate capability
  _lib.capabilities.validator.check { name = "Development"; }  # => true

  # Check if user needs creative tools
  _lib.isAnyInList config.capabilities ["creation" "multimedia"] true

  # Validate multiple capabilities
  _lib.areAllInList
    ["development" "writing"]
    _lib.capabilities.values
    true
  ```
  */
  capabilities = mkEnum [
    "writing"
    "conferencing"
    "development"
    "creation"
    "analysis"
    "management"
    "gaming"
    "multimedia"
    "administration"
    "automation"
  ];
in {
  inherit roles capabilities;

  _rootAliases = {
    userRoles = roles.values;
    userCapabilities = capabilities.values;
  };

  _tests = runTests {
    roles = {
      validatesAdmin = mkTest true (roles.validator.check "administrator");
      validatesDev = mkTest true (roles.validator.check "developer");
      correctCount = mkTest 8 (builtins.length roles.values);
    };
    capabilities = {
      validatesDevelopment = mkTest true (capabilities.validator.check "development");
      validatesGaming = mkTest true (capabilities.validator.check "gaming");
      correctCount = mkTest 10 (builtins.length capabilities.values);
    };
  };
}
