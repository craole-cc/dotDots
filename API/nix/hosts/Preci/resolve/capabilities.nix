{lix, ...}: let
  inherit (lix.attrsets) mapAttrs;
  inherit (lix.lists) elem filter;

  requirements = {
    conferencing = ["audio" "network" "webcam"];
    gaming = ["gpu"];
    multimedia = ["audio" "video"];
  };

  resolveCapability = hostFunctionalities: name: value: let
    required = requirements.${name} or [];
    missing = filter
      (functionality: !(elem functionality hostFunctionalities))
      required;
  in {
    inherit name value required missing;
    supported = missing == [];
  };
in {
  inherit requirements;

  resolve = {
    host,
    user,
  }: let
    hostFunctionalities = host.functionalities;
  in
    mapAttrs
    (resolveCapability hostFunctionalities)
    user.capabilities;
}
