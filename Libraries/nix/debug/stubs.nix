# testing/stubs.nix
#
# Minimal NixOS option/override stubs for testing modules outside a full
# nixpkgs evaluation context.
{...}: let
  /**
  Stub a `lib.mkDefault`-wrapped value (priority 1000).

  # Examples
  ```nix
  mkDefaultStub "systemd-boot"
  # => { _type = "override"; content = "systemd-boot"; priority = 1000; }
  ```
  */
  mkDefaultStub = v: {_type = "override"; content = v; priority = 1000;};

  /**
  Stub a `lib.mkForce`-wrapped value (priority 50).

  # Examples
  ```nix
  mkForceStub true
  # => { _type = "override"; content = true; priority = 50; }
  ```
  */
  mkForceStub = v: {_type = "override"; content = v; priority = 50;};

  /**
  Stub a `lib.mkEnableOption` result.

  # Examples
  ```nix
  mkEnableOptionStub "enable Wayland support"
  # => { _type = "option"; description = "enable Wayland support"; }
  ```
  */
  mkEnableOptionStub = description: {_type = "option"; inherit description;};

  exports = {inherit mkDefaultStub mkForceStub mkEnableOptionStub;};
in
  exports // {_rootAliases = exports;}
