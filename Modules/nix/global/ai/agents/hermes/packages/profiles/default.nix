{
  lix,
  writeScriptBin,
  prepare-hermes-messaging ? "",
  prepare-whatsapp-bridge ? "",
  ...
}: let
  inherit (lix.attrsets.construction) listToAttrs;

  profiles = [
    "dev"
    "lab"
    "research"
    "writing"
  ];

  mkProfile = name:
    writeScriptBin "hermes-${name}" ''
      #!/bin/sh
      set -eu
      ${prepare-hermes-messaging}
      ${prepare-whatsapp-bridge}
      exec hermes --profile ${name} "$@"
    '';
in
  listToAttrs (
    map (name: {
      name = "hermes-${name}";
      value = mkProfile name;
    })
    profiles
  )
