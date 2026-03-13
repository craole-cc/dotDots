{
  _,
  src,
  lib,
  ...
}: let
  __doc = ''
    Flake stuff
  '';

  __exports = {
    internal = {
      inherit
        getHost
        # getUser
        ;
    };
    external = {
      inherit
        getHost
        # getUser
        ;
    };
  };

  inherit (_.filesystem.flake) getFlake;
  inherit (_.hardware.system) getSystems;
  inherit (lib.attrsets) attrValues;
  inherit (lib.debug) traceIf;
  inherit (lib.lists) findFirst;

  /**
  Finds the corresponding NixOS configuration for a given system.

  Searches through explicitly provided configurations, the current flake,
  or a dynamically loaded flake to find a host matching the target system
  architecture.

  Args:
    self: The current flake (optional).
    path: Path to the flake source.
    hosts: Attribute set of defined hosts to derive a fallback system from.
    flake: Pre-evaluated flake inputs.
    nixosConfigurations: Explicit NixOS configurations to search.
    system: An explicit target system string.

  Returns:
    The matching NixOS configuration attribute set, with an appended `name`.
  */
  getHost = {
    self ? {},
    path ? src,
    hosts ? {},
    flake ? {},
    nixosConfigurations ? {},
    system ? null,
  }: let
    #> Determine the target system architecture
    targetSystem =
      if system != null
      then system
      else (getSystems {inherit hosts;}).system;

    #> Consolidate the available configurations
    configs =
      if nixosConfigurations != {}
      then nixosConfigurations
      else flake.nixosConfigurations
        or (getFlake {inherit self path;}).nixosConfigurations
        or {};

    #> Find the first host matching the target system
    #? Default to {} instead of null to prevent hard crashes on attribute access
    derived =
      findFirst
      (cfg: (cfg.config.nixpkgs.hostPlatform.system or null) == targetSystem)
      {}
      (attrValues configs);

    # Safe checks for tracing
    isValid = derived != {} && (derived.class or null) == "nixos";
    hostName = derived.config.networking.hostName or "unknown";
  in
    traceIf (!isValid)
    "❌ Failed to derive current host for system: ${targetSystem}"
    (derived // {name = hostName;});
in
  __exports.internal
  // {
    inherit __doc;
    _rootAliases = __exports.external;
  }
