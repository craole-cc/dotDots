# Module: openclaw/secrets.nix
# Purpose: sops-nix integration for all openclaw runtime secrets.
# Maintainer: openclaw-flake contributors
#
# BOOTSTRAP:
#   1. age-keygen -o ~/.config/sops/age/keys.txt
#   2. Copy the public key into .sops.yaml (see secrets/.sops.yaml.example)
#   3. cp secrets/secrets.yaml.example secrets/secrets.yaml
#   4. Fill in real values
#   5. sops --encrypt --in-place secrets/secrets.yaml
#   6. export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
#
# RULE: No secret value ever appears in a Nix store path. sops-nix decrypts
# secrets at activation time and places them in /run/secrets/, which is a
# ramfs mount not persisted to the Nix store.
{
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkDefault mkIf;

  cfg = config.services.openclaw;
in
  mkIf cfg.enable {
    sops = {
      # Template default for local development; downstream consumers should
      # override this with their own encrypted secrets file.
      defaultSopsFile = mkDefault ../../secrets/secrets.yaml.example;
      defaultSopsFormat = "yaml";

      # Age key used for decryption — set SOPS_AGE_KEY_FILE in .envrc.local.
      age.keyFile = "/var/lib/sops-nix/key.txt";

      secrets = {
        # TLS private key — only relevant when services.openclaw.tls.enable = true.
        "openclaw/tls/key" = mkIf cfg.tls.enable {
          owner = "openclaw";
          group = "openclaw";
          mode = "0400";
        };

        # TLS certificate — only relevant when services.openclaw.tls.enable = true.
        "openclaw/tls/cert" = mkIf cfg.tls.enable {
          owner = "openclaw";
          group = "openclaw";
          mode = "0444";
        };

        # Example application secret (API token, database password, etc.).
        "openclaw/api-secret" = {
          owner = "openclaw";
          group = "openclaw";
          mode = "0400";
        };
      };
    };

    # Wire the sops-decrypted paths back into the openclaw TLS config.
    services.openclaw.tls = mkIf cfg.tls.enable {
      certFile = mkDefault config.sops.secrets."openclaw/tls/cert".path;
      keyFile = mkDefault config.sops.secrets."openclaw/tls/key".path;
    };
  }
