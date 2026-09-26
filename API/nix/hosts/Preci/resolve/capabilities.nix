{lix, ...}: let
  requirements = {
    conferencing = ["audio" "network" "webcam"];
    gaming = ["gpu"];
    multimedia = ["audio" "video"];
  };

  resolveCapability = hostFunctionalities: name: value: let
    required = requirements.${name} or [];
    missing = lix.lists.filter
      (functionality: !(lix.lists.elem functionality hostFunctionalities))
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
    lix.attrsets.mapAttrs
    (resolveCapability hostFunctionalities)
    user.capabilities;
}
