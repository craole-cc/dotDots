{lix, ...}: let
  inherit (lix.attrsets) mapAttrs;
  inherit (lix.lists) elem filter;
  requirements = lix.schema.user.capabilityRequirements;
  resolveCapability = hostFunctionalities: name: value: let
    required = (requirements.${name} or {}).functionalities or [];
    missing = filter (functionality: !(elem functionality hostFunctionalities)) required;
  in { inherit name value required missing; supported = missing == []; };
in {
  resolve = {host, user}: let hostFunctionalities = host.functionalities; in
    mapAttrs (resolveCapability hostFunctionalities) user.capabilities;
}
