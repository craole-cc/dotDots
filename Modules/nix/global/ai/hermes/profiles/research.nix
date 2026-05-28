{
  helpers,
  runtimes,
  ...
}: let
  inherit (helpers)
    mkBin
    prepare-hermes-messaging
    prepare-whatsapp-bridge
    ;
in {
  hermes-research = mkBin "hermes-research" runtimes.hermes ''
    ${prepare-hermes-messaging}
    ${prepare-whatsapp-bridge}
    exec hermes --profile research "$@"
  '';
}
