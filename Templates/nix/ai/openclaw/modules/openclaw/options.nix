{
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib.options)
    literalExpression
    mkOption
    mkEnableOption
    ;
  inherit
    (lib.types)
    attrs
    enum
    listOf
    nullOr
    package
    port
    path
    str
    ;
in {
  options.services.openclaw = {
    enable = mkEnableOption "Whether to enable the openclaw service.";

    package = mkOption {
      type = package;
      default = pkgs.openclaw;
      defaultText = literalExpression "pkgs.openclaw";
      description = "The openclaw derivation to use.";
      example = literalExpression "pkgs.openclaw";
    };

    port = mkOption {
      type = port;
      default = 8080;
      description = "TCP port that openclaw listens on.";
      example = 9090;
    };

    host = mkOption {
      type = str;
      default = "127.0.0.1";
      description = "IP address openclaw binds to.";
      example = "0.0.0.0";
    };

    dataDir = mkOption {
      type = path;
      default = "/var/lib/openclaw";
      description = "Directory for openclaw persistent state.";
      example = "/srv/openclaw";
    };

    logLevel = mkOption {
      type = enum ["debug" "info" "warn" "error"];
      default = "info";
      description = "Log verbosity level.";
      example = "debug";
    };

    openFirewall = mkEnableOption "Open the firewall for services.openclaw.port.";

    tls = {
      enable = mkEnableOption "Enable TLS on the openclaw listener.";

      certFile = mkOption {
        type = nullOr path;
        default = null;
        description = "Path to the TLS certificate file. Required when tls.enable = true.";
        example = literalExpression ''config.sops.secrets."openclaw/cert".path'';
      };

      keyFile = mkOption {
        type = nullOr path;
        default = null;
        description = "Path to the TLS private key file. Required when tls.enable = true. Must never be in the Nix store.";
        example = literalExpression ''config.sops.secrets."openclaw/key".path'';
      };
    };

    extraConfig = mkOption {
      type = attrs;
      default = {};
      description = "Freeform extra configuration passed to openclaw as JSON.";
      example = {
        maxConnections = 1000;
        requestTimeout = 30;
      };
    };

    allowedIPs = mkOption {
      type = listOf str;
      default = [];
      description = ''
        IP address ranges allowed through the systemd IPAddressAllow directive.
        When non-empty, systemd will deny all other IPs at the cgroup level.
        Use CIDR notation, e.g. "10.0.0.0/8".
      '';
      example = [
        "10.0.0.0/8"
        "127.0.0.1/32"
      ];
    };
  };
}
