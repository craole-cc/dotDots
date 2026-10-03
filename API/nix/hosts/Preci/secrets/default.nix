#? Host-level SOPS secrets.
#?
#? This directory is self-contained: `secrets.yaml` holds the encrypted values,
#? and this module declares how they are decrypted onto the running system.
#?
#? Creation rules live one level up, in the host's own `.sops.yaml`, which is
#? what `sups` passes explicitly and what sops finds by walking up from here.
#?
#? Per-principal secrets are *not* declared here. They live with their
#? principal under `specs/users/<name>/` and are provisioned by Home Manager,
#? so one principal's credentials are never readable by another.
{config, ...}: {
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
      sopsFile = ./secrets.yaml;
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };

  #? Tailscale reads its auth key from the decrypted path. Without this the
  #? service starts but never joins the tailnet.
  services.tailscale.authKeyFile = config.sops.secrets."tailscale/authkey".path;
}
