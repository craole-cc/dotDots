{
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkMerge mkIf;

  cfg = config.services.openclaw;
in
  mkIf (cfg.enable && cfg.tls.enable) {
    # Validate that cert and key paths are provided when TLS is enabled.
    assertions = [
      {
        assertion = cfg.tls.certFile != null;
        message = "services.openclaw.tls.certFile must be set when tls.enable = true.";
      }
      {
        assertion = cfg.tls.keyFile != null;
        message = "services.openclaw.tls.keyFile must be set when tls.enable = true.";
      }
    ];

    # When openclaw uses nginx as a TLS front-end (see networking.nix), these
    # ssl_protocols and ssl_ciphers settings are applied there.  The values
    # below are also written to the openclaw JSON config so the built-in
    # listener can honour them if nginx is disabled.
    services.openclaw.extraConfig = mkMerge [
      (mkIf cfg.tls.enable {
        tls = {
          protocols = ["TLSv1.2" "TLSv1.3"];
          #? TLS 1.3 cipher suites (selected automatically by OpenSSL).
          ciphersTLS13 = [
            "TLS_AES_256_GCM_SHA384"
            "TLS_CHACHA20_POLY1305_SHA256"
          ];
          #? TLS 1.2 cipher suites (explicit allowlist).
          ciphersTLS12 = [
            "ECDHE-ECDSA-AES256-GCM-SHA384"
            "ECDHE-RSA-AES256-GCM-SHA384"
          ];
          hstsMaxAge = 31536000;
          hstsIncludeSubDomains = true;
          hstsPreload = true;
          ocspStapling = true;
        };
      })
    ];
  }
