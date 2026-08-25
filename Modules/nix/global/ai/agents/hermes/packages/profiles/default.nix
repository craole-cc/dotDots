{
  writeScriptBin,
  prepare-hermes-messaging ? "",
  prepare-whatsapp-bridge ? "",
  ...
}: let
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
  builtins.listToAttrs (
    map (name: {
      name = "hermes-${name}";
      value = mkProfile name;
    })
    profiles
  )
