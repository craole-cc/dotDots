#? Per-principal SOPS secrets, split by ownership.
#?
#? sops applies recipients per *file*, so keys with different owners have to
#? live in different files. Putting a per-host OpenRouter key and a user-wide
#? DeepSeek key in one file would force a single recipient set on both:
#?
#?   secrets/host.yaml  Keys issued per host, so spend can be attributed to
#?                      one. OpenRouter, NVIDIA and Nous all support multiple
#?                      keys, so each host holds its own. Readable only by the
#?                      host the key was issued for, plus the recovery key.
#?
#?   secrets/user.yaml  Credentials that are not per-host: a personal bot token,
#?                      or anything billed to the account and valid everywhere.
#?                      Readable by this user wherever they log in.
#?
#? The names match the vocabulary used elsewhere in this repo -- hosts/<host>/,
#? users/<user>/, `sups --host` / `--user` -- so a file's basename says who can
#? read it.
#?
#? Both files are decrypted and concatenated into the agent's environment, host
#? first, so a per-host value wins over a user-wide one of the same name. They
#? are declared by name rather than discovered: a missing file fails loudly at
#? activation instead of silently contributing nothing, which is the failure
#? mode worth having for a credential.
#?
#? Only `mode` is set: `sops.homeManagerModules` has no `owner`/`group`
#? options. That is not a gap -- a Home Manager secret is written into the
#? user's own home directory, so it is already owned by that user.
{
  config,
  ...
}: let
  inherit (config.home) homeDirectory username;

  #? `specs/users/<username>/secrets/`, resolved from this module's location
  #? (`modules/home/`) up to the host root.
  secretsDir = ../../specs/users/${username}/secrets;

  host = {
    sopsFile = "${secretsDir}/host.yaml";
    mode = "0600";
  };

  user = {
    sopsFile = "${secretsDir}/user.yaml";
    mode = "0600";
  };
in {
  sops = {
    #? The principal's own age identity. For the user-scoped file this is the
    #? keypair `.sops.yaml` lists under that principal's anchor; sops only
    #? ever needs the private half.
    age.keyFile = "${homeDirectory}/.config/sops/age/keys.txt";

    #? `sops.secrets` is a flat attrset of secret *names* -- there is no
    #? nesting -- so the two classes are named `hermes/host` and `hermes/user`
    #? rather than nested under a `hermes` parent.
    secrets."hermes/host" = host;
    secrets."hermes/user" = user;
  };

  #? The agent reads its credentials from the decrypted files rather than from
  #? its own environment, so the values never land in the world-readable
  #? environment or in a store path.
  services.hermes-agent.environmentFiles = [
    config.sops.secrets."hermes/host".path
    config.sops.secrets."hermes/user".path
  ];
}