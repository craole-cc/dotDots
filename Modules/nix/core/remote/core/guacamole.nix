{
  config,
  host,
  lix,
  pkgs,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext mkForce;
  inherit (lix.options.construction) mkOption;
  inherit (lix.types.combinators) nullOr;
  inherit (lix.types.primitives) bool int path str;

  context = mkContext {
    inherit config;
    dom = "remote";
    sub = "core";
    mod = "guacamole";
  };
  inherit (context) cfg;

  generatedUserMappingXml =
    if cfg.passwordHash == null
    then null
    else
      pkgs.writeText "guacamole-user-mapping.xml" ''
        <user-mapping>
          <authorize username="${cfg.username}" password="${cfg.passwordHash}" encoding="md5">
            <connection name="${cfg.desktopName}">
              <protocol>vnc</protocol>
              <param name="hostname">127.0.0.1</param>
              <param name="port">${toString cfg.vncPort}</param>
            </connection>
          </authorize>
        </user-mapping>
      '';
  mappingXml =
    if cfg.userMappingXml != null
    then cfg.userMappingXml
    else generatedUserMappingXml;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkOption {
        description = "Enable the Guacamole remote-desktop gateway over Tailscale";
        default = host.access.remote.guacamole.enable or false;
        type = bool;
      };
      host = mkOption {
        description = "Loopback address on which guacd listens";
        default = host.access.remote.guacamole.host or "127.0.0.1";
        type = str;
      };
      port = mkOption {
        description = "Local guacd port used by the Guacamole web client";
        default = host.access.remote.guacamole.port or 4822;
        type = int;
      };
      webPort = mkOption {
        description = "Tomcat port exposed only through tailscale0";
        default = host.access.remote.guacamole.webPort or 8080;
        type = int;
      };
      userMappingXml = mkOption {
        description = "Guacamole user and connection mapping; it is copied into the Nix store, so it must not contain plaintext secrets";
        default = host.access.remote.guacamole.userMappingXml or null;
        type = nullOr path;
      };
      username = mkOption {
        description = "Guacamole username for the generated local WayVNC connection";
        default = host.access.remote.guacamole.username or "craole";
        type = str;
      };
      passwordHash = mkOption {
        description = "MD5 hash of the Guacamole password for the generated local WayVNC connection";
        default = host.access.remote.guacamole.passwordHash or null;
        type = nullOr str;
      };
      desktopName = mkOption {
        description = "Name shown for the generated local WayVNC connection";
        default = host.access.remote.guacamole.desktopName or "Victus desktop";
        type = str;
      };
      desktopUser = mkOption {
        description = "Desktop user whose Hyprland session runs WayVNC";
        default = host.access.remote.guacamole.desktopUser or null;
        type = nullOr str;
      };
      vncPort = mkOption {
        description = "Loopback-only WayVNC port used by Guacamole";
        default = host.access.remote.guacamole.vncPort or 5900;
        type = int;
      };
    };

    outputs = {
      assertions = [
        {
          assertion = cfg.userMappingXml != null || cfg.passwordHash != null;
          message = "remote.guacamole requires a userMappingXml or passwordHash; do not expose a passwordless desktop.";
        }
        {
          assertion = cfg.desktopUser != null;
          message = "remote.guacamole requires desktopUser so WayVNC runs only in the intended graphical session.";
        }
      ];

      services = {
        guacamole-server = {
          inherit (cfg) enable host port;
        };
        guacamole-client = {
          inherit (cfg) enable;
          userMappingXml = mappingXml;
          settings = {
            guacd-hostname = cfg.host;
            guacd-port = cfg.port;
          };
        };
        tomcat.port = cfg.webPort;
      };

      programs.wayvnc.enable = cfg.enable;

      networking.firewall = {
        # Tomcat listens on all local interfaces. The firewall is therefore
        # mandatory to make the web gateway Tailscale-only.
        enable = mkForce true;
        interfaces.tailscale0.allowedTCPPorts = [cfg.webPort];
      };
    };
  }
