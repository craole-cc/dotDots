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
  hermes-dev = mkBin "hermes-dev" runtimes.hermes ''
    ${prepare-hermes-messaging}
    ${prepare-whatsapp-bridge}
    exec hermes --profile dev "$@"
  '';
}
