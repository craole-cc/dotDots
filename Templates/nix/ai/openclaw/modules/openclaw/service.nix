{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.lists) optional;
  inherit (lib.meta) getExe;
  inherit (lib.strings) toJSON;
  inherit (lib.modules) mkIf;
  inherit (pkgs) writeText;

  cfg = config.services.openclaw;

  #> Build the openclaw config JSON from extraConfig merged with core options.
  configFile = writeText "openclaw.json" (
    toJSON (
      cfg.extraConfig
      // {
        host = cfg.host;
        port = cfg.port;
        dataDir = cfg.dataDir;
        logLevel = cfg.logLevel;
        tls = optionalAttrs cfg.tls.enable {
          enable = true;
          certFile = cfg.tls.certFile;
          keyFile = cfg.tls.keyFile;
        };
      }
    )
  );
in
  mkIf cfg.enable {
    #> Ensure the data directory exists with correct ownership.
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 openclaw openclaw - -"
    ];

    systemd.services.openclaw = {
      description = "OpenClaw Service";
      documentation = ["https://github.com/your-org/openclaw"];
      wantedBy = ["multi-user.target"];
      after = [
        "network-online.target"
        "nss-lookup.target"
      ];
      wants = ["network-online.target"];

      serviceConfig = {
        ExecStart = "${getExe cfg.package} --config ${configFile}";
        Restart = "on-failure";
        RestartSec = "5s";

        # ── Identity ──────────────────────────────────────────────────────────
        # DynamicUser allocates a transient UID/GID at start time; no /etc/passwd
        # entry is required and the user ceases to exist when the service stops.
        DynamicUser = true;
        User = "openclaw";
        Group = "openclaw";

        # ── File-system isolation ─────────────────────────────────────────────
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [cfg.dataDir];

        # ── Privilege containment ─────────────────────────────────────────────
        NoNewPrivileges = true;
        RestrictSUIDSGID = true;
        MemoryDenyWriteExecute = true;
        LockPersonality = true;
        RestrictRealtime = true;

        # ── Capability dropping ───────────────────────────────────────────────
        CapabilityBoundingSet = [""]; # empty string = drop all

        # ── Networking ────────────────────────────────────────────────────────
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        # Default-deny; override with services.openclaw.allowedIPs.
        IPAddressDeny = "any";
        IPAddressAllow =
          optional (cfg.host != "0.0.0.0") cfg.host
          ++ cfg.allowedIPs
          ++ [
            "127.0.0.1/32"
            "::1/128"
          ];

        # ── Kernel hardening ──────────────────────────────────────────────────
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;

        # ── Syscall filtering ─────────────────────────────────────────────────
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
          "~@resources"
        ];
        SystemCallArchitectures = "native";

        # ── Misc ──────────────────────────────────────────────────────────────
        UMask = "0027";
        StateDirectory = "openclaw";
        LogsDirectory = "openclaw";
        ConfigurationDirectory = "openclaw";
      };
    };
  }
