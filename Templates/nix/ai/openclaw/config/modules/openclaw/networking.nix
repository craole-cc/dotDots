{
  config,
  lib,
  ...
}: let
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) concatStringsSep optionalString;

  cfg = config.services.openclaw;
  inherit (config.services) nginx;
  inherit (cfg) tls;

  #? Common security headers applied in both nginx and caddy snippets.
  securityHeaders = {
    "X-Frame-Options" = "DENY";
    "X-Content-Type-Options" = "nosniff";
    "Referrer-Policy" = "strict-origin-when-cross-origin";
    "Content-Security-Policy" = "default-src 'self'";
    "Permissions-Policy" = "geolocation=(), microphone=(), camera=()";
  };

  nginxHeaderLines = concatStringsSep "\n    " (
    mapAttrsToList (k: v: ''add_header "${k}" "${v}" always;'') securityHeaders
  );
in
  mkIf cfg.enable {
    # ── Firewall ───────────────────────────────────────────────────────────────
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [cfg.port];
    };

    # ── nginx reverse-proxy snippet ────────────────────────────────────────────
    # Include this in your NixOS nginx config with:
    #   services.nginx.virtualHosts."openclaw.example.com" =
    #     config.services.openclaw._nginxVhostAttrs;
    services.openclaw._nginxVhostAttrs = mkIf nginx.enable {
      forceSSL = tls.enable;
      enableACME = tls.enable;

      extraConfig = ''
        # Security headers
        ${nginxHeaderLines}

        ${optionalString tls.enable ''
          # TLS hardening
          ssl_protocols TLSv1.2 TLSv1.3;
          ssl_ciphers "TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384";
          ssl_prefer_server_ciphers on;
          ssl_session_cache shared:SSL:10m;
          ssl_session_timeout 1d;
          ssl_session_tickets off;
          ssl_stapling on;
          ssl_stapling_verify on;
          add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
        ''}
      '';

      locations."/" = {
        proxyPass = "http${
          if tls.enable
          then "s"
          else ""
        }://${cfg.host}:${toString cfg.port}";
        proxyWebsockets = true;

        extraConfig = ''
          proxy_set_header Host              $host;
          proxy_set_header X-Real-IP         $remote_addr;
          proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;

          # Security headers at proxy layer too
          ${nginxHeaderLines}
        '';
      };
    };

    # ── Caddy reverse-proxy snippet ────────────────────────────────────────────
    # Append this to services.caddy.virtualHosts.<domain>.extraConfig.
    #
    #   services.caddy.virtualHosts."openclaw.example.com".extraConfig = ''
    #     ${config.services.openclaw._caddySnippet}
    #   '';
    services.openclaw._caddySnippet = ''
      reverse_proxy ${cfg.host}:${toString cfg.port} {
        header_up Host              {host}
        header_up X-Real-IP         {remote_host}
        header_up X-Forwarded-For   {remote_host}
        header_up X-Forwarded-Proto {scheme}
      }

      header {
        X-Frame-Options           "DENY"
        X-Content-Type-Options    "nosniff"
        Referrer-Policy           "strict-origin-when-cross-origin"
        Content-Security-Policy   "default-src 'self'"
        Permissions-Policy        "geolocation=(), microphone=(), camera=()"
        ${optionalString tls.enable ''Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"''}
      }

      ${optionalString tls.enable "tls { protocols tls1.2 tls1.3 }"}
    '';
  }
