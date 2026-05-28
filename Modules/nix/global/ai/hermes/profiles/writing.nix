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
  hermes-writing = mkBin "hermes-writing" runtimes.hermes ''
    ${prepare-hermes-messaging}
    ${prepare-whatsapp-bridge}
    exec hermes --profile writing "$@"
  '';
}
