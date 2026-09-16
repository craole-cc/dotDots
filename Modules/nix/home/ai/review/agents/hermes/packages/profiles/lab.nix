{
  helpers,
  runtimes,
  ...
}: let
  inherit
    (helpers)
    mkBin
    prepare-hermes-messaging
    prepare-whatsapp-bridge
    ;
in {
  hermes-lab = mkBin "hermes-lab" runtimes.hermes ''
    ${prepare-hermes-messaging}
    ${prepare-whatsapp-bridge}
    exec hermes --profile lab "$@"
  '';
}
