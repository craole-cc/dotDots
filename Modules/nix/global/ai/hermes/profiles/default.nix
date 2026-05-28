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
  hermes-tui = mkBin "hermes-tui" runtimes.hermes ''
    ${prepare-hermes-messaging}
    ${prepare-whatsapp-bridge}
    exec hermes "$@"
  '';
}
