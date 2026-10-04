#? Per-principal SOPS secrets, split by ownership.
#?
#? sops applies recipients per *file*, so credentials with different owners
#? have to live in different files. Putting a per-host provider key and a
#? user-wide bot token in one file would force a single recipient set on both:
#?
#?   secrets/host.yaml  Credentials the agent consumes on this host: inference-
#?                      provider keys, one per host, so spend can be traced to
#?                      the machine that made it. Scoped this way on purpose:
#?                      if every host could read every key, per-host attribution
#?                      would record nothing. Readable only by the host the keys
#?                      were issued for, plus the recovery key.
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
  lix,
  ...
}: let
  inherit (config.home) homeDirectory username;
  inherit (lix.strings) mkPath mkPathLiteral;
in {
  sops = {
    #? The principal's own age identity. For the user-scoped file this is the
    #? keypair `.sops.yaml` lists under that principal's anchor; sops only
    #? ever needs the private half.
    age = {
      keyFile = mkPathLiteral homeDirectory [
        ".config"
        "sops"
        "age"
        "keys.txt"
      ];
    };
    #? `sops.secrets` is a flat attrset of secret *names* -- there is no
    #? nesting -- so the two classes are named `hermes/host` and `hermes/user`
    #? rather than nested under a `hermes` parent.
    secrets = let
      mkSops = scope: let
        # TODO: I don't like relative paths like this, we should be using paths.* or we should have this already as an attrset
        # ../../specs/users/${username}/secrets;
        secrets = mkPath ["specs" "users" username "secrets"];
      in {
        mode = "0600";
        sopsFile = mkPath paths.users ["users" username "secrets" "${scope}.yaml"];
      };
      mkSopsHermes = scope: {"hermes/${scope}" = mkSops "${scope}";};
    in
      mkSopsHermes "host" // mkSopsHermes "user";
  };

  #? The agent reads its credentials from the decrypted files rather than from
  #? its own environment, so the values never land in the world-readable
  #? environment or in a store path.
  services = {
    hermes-agent = let
      mkEnv = scope: [config.sops.secrets."hermes/${scope}".path];
    in {environmentFiles = (mkEnv "host") ++ (mkEnv "user");};
  };
}
