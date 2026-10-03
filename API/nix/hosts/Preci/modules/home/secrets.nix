#? Per-principal SOPS secrets, split by ownership.
#?
#? sops applies recipients per *file*, so keys with different owners have to
#? live in different files. Putting a per-host OpenRouter key and a per-person
#? NVIDIA key in one file would force a single recipient set on both:
#?
#?   secrets/machine.yaml  Keys issued per host, so spend can be attributed to
#?                         a machine -- OpenRouter, NVIDIA and Nous all support
#?                         multiple keys, so each host holds its own. Readable
#?                         only by the host the key was issued for, plus the
#?                         recovery key.
#?
#?   secrets/person.yaml   Credentials that are not per-machine: a personal bot
#?                         token, or anything billed to the account and valid
#?                         everywhere. Readable by the principal wherever they
#?                         log in.
#?
#? Both are decrypted and concatenated into the agent's environment. The files
#? are declared by name rather than discovered, so a principal that has only
#? one is expected to have only that one -- a missing file fails loudly at
#? activation instead of silently contributing nothing.
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

  #? The two ownership classes, in the order the agent reads them. Later files
  #? win on a name collision, so a host may shadow a person-wide default.
  machine = {
    sopsFile = "${secretsDir}/machine.yaml";
    mode = "0600";
  };

  person = {
    sopsFile = "${secretsDir}/person.yaml";
    mode = "0600";
  };
in {
  sops = {
    #? The principal's own age identity. For person-owned files this is the
    #? keypair `.sops.yaml` lists under that principal's anchor; sops only
    #? ever needs the private half.
    age.keyFile = "${homeDirectory}/.config/sops/age/keys.txt";

    secrets.hermes = {
      inherit machine person;
    };
  };

  #? The agent reads its credentials from the decrypted files rather than from
  #? its own environment, so the values never land in the world-readable
  #? environment or in a store path.
  services.hermes-agent.environmentFiles = [
    config.sops.secrets.hermes.machine.path
    config.sops.secrets.hermes.person.path
  ];
}