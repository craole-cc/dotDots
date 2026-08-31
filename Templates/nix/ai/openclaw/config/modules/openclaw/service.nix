{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.lists) optional;
  inherit (lib.meta) getExe;
  inherit (lib.strings) hasPrefix removePrefix toJSON;
  inherit (lib.modules) mkIf;
  inherit (pkgs) writeText;

  cfg = config.services.openclaw;
  dataDir = toString cfg.dataDir;
  stateDirectory = removePrefix "/var/lib/" dataDir;
  managesDataDir = hasPrefix "/var/lib/" dataDir;

  #> Build the openclaw config JSON from extraConfig merged with core options.
  configFile = writeText "openclaw.json" (
    toJSON (
      cfg.extraConfig
      // {
        inherit (cfg) host;
        inherit (cfg) port;
        inherit (cfg) dataDir;
        inherit (cfg) logLevel;
        tls = optionalAttrs cfg.tls.enable {
          enable = true;
          inherit (cfg.tls) certFile;
          inherit (cfg.tls) keyFile;
        };
      }
    )
  );
in
  mkIf cfg.enable {
    assertions = [
      {
        assertion = managesDataDir;
        message = "services.openclaw.dataDir must live under /var/lib when DynamicUser = true.";
      }
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
        ReadWritePaths = [dataDir];

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
        StateDirectory = stateDirectory;
        LogsDirectory = "openclaw";
        ConfigurationDirectory = "openclaw";
      };
    };
  }
