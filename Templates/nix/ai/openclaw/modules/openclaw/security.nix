{
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkDefault mkIf;
  inherit (lib.strings) optionalString;
  cfg = config.services.openclaw;
in
  mkIf cfg.enable {
    # ── AppArmor ──────────────────────────────────────────────────────────────
    security.apparmor = {
      enable = mkDefault true;

      policies."openclaw" = {
        enable = true;
        enforce = true;

        profile = ''
          #include <tunables/global>

          profile openclaw flags=(attach_disconnected, mediate_deleted) {
            #include <abstractions/base>
            #include <abstractions/nameservice>
            #include <abstractions/ssl_certs>

            # Binary
            ${config.services.openclaw.package}/bin/openclaw mr,

            # Data directory
            ${cfg.dataDir}/ r,
            ${cfg.dataDir}/** rwk,

            # TLS certificates (if enabled)
            ${optionalString cfg.tls.enable ''
            ${optionalString (cfg.tls.certFile != null) "${cfg.tls.certFile} r,"}
            ${optionalString (cfg.tls.keyFile != null) "${cfg.tls.keyFile} r,"}
          ''}

            # Proc (limited)
            /proc/self/status r,
            /proc/sys/kernel/hostname r,

            # Sockets — allow TCP bind only
            network inet  stream,
            network inet6 stream,

            # Deny everything else
            deny /etc/shadow r,
            deny @{HOME}/** rwx,
            deny /root/** rwx,
          }
        '';
      };
    };

    # ── seccomp (via systemd SystemCallFilter — also set in service.nix) ──────
    # The primary seccomp enforcement happens in service.nix via
    # SystemCallFilter = [ "@system-service" "~@privileged" "~@resources" ].
    # This comment documents the intent; no duplicate config is needed here.
  }
