#? Host-level SOPS secrets.
#?
#? The encrypted values live with the rest of this host's declarations, in
#? `specs/secrets.yaml`, so a module never sits next to the data it declares
#? and every encrypted file for the host is under one root. Per-principal
#? secrets follow the same rule under `specs/users/<name>/secrets/`.
#?
#? Creation rules live in the host's own `.sops.yaml`, which is what `sups`
#? passes explicitly and what sops finds by walking up from the file.
#?
#? Per-principal secrets are *not* declared here. They live with their
#? principal and are provisioned by Home Manager, so one principal's
#? credentials are never readable by another.
{
  config,
  host,
  lix,
  ...
}: let
  inherit (lix.strings) mkPath;
in {
  sops = {
    age = {
      keyFile = "/var/lib/sops-nix/key.txt";

      #? Generates the host key on first activation. A host that must read
      #? pre-existing ciphertext needs that key provisioned out of band
      #? instead: a freshly generated key cannot decrypt anything.
      generateKey = true;
    };

    #? A tailscale authkey is a bearer credential, so it lands root-owned and
    #? mode 0400 -- never group- or world-readable.
    secrets."tailscale/authkey" = {
      sopsFile = mkPath host.paths.specs ["secrets.yaml"];
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };

  #? Tailscale reads its auth key from the decrypted path. Without this the
  #? service starts but never joins the tailnet.
  services.tailscale.authKeyFile = config.sops.secrets."tailscale/authkey".path;
}
