{_, ...}: let
  mkVal = _.lists.makeCaseInsensitiveListValidator;
in {
  /**
  User roles - system access and privilege levels.

  Defines user account types and their associated privilege levels.

  # Roles
  - administrator: Full system administrator with unrestricted root access
  - developer: Developer account with sudo access and development tools
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
  _lib.userRoles.validator.check { name = "Developer"; }  # => true

  # Check if user has elevated privileges
  _lib.isAnyInList [config.role] ["administrator" "developer" "poweruser"] true

  # Get all available roles
  _lib.userRoles.values
  ```
  */
  userRoles = let
    values = [
      "administrator"
      "developer"
      "poweruser"
      "user"
      "guest"
      "service"
    ];
  in {
    inherit values;
    validator = mkVal values;
  };

  /**
  User capabilities - primary use cases and workflows.

  Defines what the user primarily does with their system.
  Used to configure appropriate applications and optimizations.

  # Capabilities
  - writing: Document creation, note-taking, content writing
  - conferencing: Video calls, screen sharing, remote meetings
  - development: Software development and programming
  - creation: Creative work (art, music, video production)
  - analysis: Data analysis, spreadsheets, visualization
  - management: Project/task management, organization
  - gaming: Gaming and entertainment
  - multimedia: Media consumption and light editing

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
  _lib.userCapabilities.validator.check { name = "Development"; }  # => true

  # Check if user needs creative tools
  _lib.isAnyInList config.capabilities ["creation" "multimedia"] true

  # Validate multiple capabilities
  _lib.areAllInList
    ["development" "writing"]
    _lib.userCapabilities.values
    true
  ```
  */
  userCapabilities = let
    values = [
      "writing"
      "conferencing"
      "development"
      "creation"
      "analysis"
      "management"
      "gaming"
      "multimedia"
    ];
  in {
    inherit values;
    validator = mkVal values;
  };
}
