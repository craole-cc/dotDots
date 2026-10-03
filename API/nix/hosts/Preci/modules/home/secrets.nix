#? Per-principal SOPS secrets.
#?
#? Each principal's encrypted file lives beside its profile under
#? `specs/users/<name>/`, with a matching `.sops.yaml`. Secrets are decrypted
#? per-principal rather than once on the host so one principal's credentials
#? are never readable by another's Home Manager generation.
#?
#? `home.username` is set by `user.nix` from the resolved principal, so the
#? secret file is selected from the principal's own name rather than a literal.
#? Adding a second principal therefore needs no change here.
#?
#? Only `mode` is set: `sops.homeManagerModules` has no `owner`/`group`
#? options. That is not a gap -- a Home Manager secret is written into the
#? user's own home directory, so it is already owned by that user.
{
  config,
  ...
}: let
  homeDirectory = config.home.homeDirectory;
  username = config.home.username;

  #? `specs/users/<username>/`, resolved from this module's location
  #? (`modules/home/`) up to the host root.
  specDir = ../../specs/users/${username};
in {
  sops = {
    age.keyFile = "${homeDirectory}/.config/sops/age/keys.txt";

    secrets."hermes/env" = {
      sopsFile = "${specDir}/secrets.yaml";
      mode = "0600";
    };
  };

  #? The agent reads its credentials from the decrypted file rather than from
  #? its own environment, so the values never land in the world-readable
  #? environment or in a store path.
  services.hermes-agent.environmentFiles = [
    config.sops.secrets."hermes/env".path
  ];
}