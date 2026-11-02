{
  bots,
  cfg,
  common,
  config,
  interface,
  lib,
  lix,
  pkgs,
  runtime,
  ...
}: let
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.attrsets.transformation) filterAttrs mapAttrsToList;
  inherit (lix.lists.aggregation) concatMap;
  inherit (lix.modules.construction) mkIf;
  inherit (lix.options.construction) mkOption mkTrue;
  inherit (lix.strings.construction) concatStringsSep toJSON;
  inherit (lix.strings.access) match;
  inherit (lix.strings.transformation) escapeShellArg escapeShellArgs;
  inherit (lix.types.combinators) attrsOf nullOr submodule;
  inherit (lix.types.primitives) str;

  service = config.services.hermes-agent;
  active = filterAttrs (_name: profile: profile.enable) cfg.profiles;
  upstreamOptions = common.sharedOptions {
    defaultPackage = service.package;
    defaultPackageText = "services.hermes-agent.package";
    defaultWorkingDirectory = service.workingDirectory;
    defaultWorkingDirectoryText = "services.hermes-agent.workingDirectory";
  };
  profileOptions = {
    inherit
      (upstreamOptions)
      settings
      environment
      environmentFiles
      authFile
      authFileForceOverwrite
      documents
      hermesHomeFiles
      mcpServers
      extraPlugins
      ;
  };
  inherit
    ((common.mkConfigFiles {
      inherit pkgs;
      cfg = service;
      inherit (service) workingDirectory;
    }))
    mergeScript
    ;

  profileConfig = profile:
    service
    // (interface.config profileOptions profile)
    // {
      configFile = null;
      workingDirectory =
        if profile.workingDirectory == null
        then service.workingDirectory
        else profile.workingDirectory;
      settings = recursiveUpdate profile.settings (
        optionalAttrs (profile.mcpServers != {}) {
          mcp_servers = common.mcpServersToConfig profile.mcpServers;
        }
      );
    };

  setup = name: profile: let
    resolved = profileConfig profile;
    homePath = "${cfg.home.path}/profiles/${name}";
    metadata = pkgs.writeText "hermes-${name}-metadata.json" (toJSON (
      optionalAttrs (profile.description != null) {
        inherit (profile) description;
        description_auto = false;
      }
      // bots.metadata name profile
    ));
  in ''
    ${common.mkStateScript {
      inherit pkgs;
      hermesHome = homePath;
      cfg = resolved;
      inherit (resolved) workingDirectory;
      run = "$DRY_RUN_CMD ";
      stateDirs = common.stateSubdirs;
      managedSystem = "home-manager";
      modes = {
        config = "0600";
        env = "0600";
        managed = "0600";
        auth = "0600";
        document = "0600";
      };
    }}
    $DRY_RUN_CMD ${mergeScript} ${metadata} ${escapeShellArg "${homePath}/profile.yaml"}
    $DRY_RUN_CMD chmod 0600 ${escapeShellArg "${homePath}/profile.yaml"}
  '';
in {
  options.profiles = mkOption {
    type = attrsOf (submodule ({name, ...}: {
      options =
        (interface.options profileOptions)
        // {
          home.file =
            upstreamOptions.hermesHomeFiles
            // {
              description = "Files installed in this profile's directory beneath home.path/profiles, such as SOUL.md and memories/USER.md";
            };
          documents =
            upstreamOptions.documents
            // {
              description = "Workspace files installed relative to this profile's explicit workingDirectory; use home.file for identity and memory files";
            };
          enable = mkTrue "Manage this named Hermes profile during Home Manager activation.";
          description = mkOption {
            type = nullOr str;
            default = null;
            description = "Public role description in profile.yaml. Null preserves a runtime description.";
          };
          workingDirectory = mkOption {
            type = nullOr str;
            default = null;
            description = "Tool working directory. Null uses the main Hermes working directory; documents need an explicit path.";
          };
        }
        // bots.profileOptions name;
    }));
    default = {};
    description = ''
      Named profiles beneath home.path/profiles.
      Settings and metadata merge into writable files using the flake's Hermes helpers.
      Each profile has its own secret sources; credentials are not inherited from the main profile.
      Removing a declaration preserves that profile's runtime directory and history.
    '';
  };

  outputs = {
    assertions = concatMap (name: let
      profile = active.${name};
    in
      [
        {
          assertion = name != "default" && match "[a-z0-9][a-z0-9_-]{0,63}" name != null;
          message = "Hermes profile '${name}' needs a lowercase profile name of at most 64 characters; configure default through settings.";
        }
        {
          assertion = profile.documents == {} || profile.workingDirectory != null;
          message = "Hermes profile '${name}' documents require an explicit workingDirectory.";
        }
      ]
      ++ common.pluginNameAssertions {
        cfg = interface.config profileOptions profile;
        optionPath = "Hermes profiles.${name}";
      }) (attrNames active);

    home.activation.hermesProfiles = mkIf (active != {}) (
      lib.hm.dag.entryBetween ["reloadSystemd"] ["hermesAgentSetup"] (
        ''
          $DRY_RUN_CMD ${runtime.package.hermesVenv}/bin/python3 -c \
            ${escapeShellArg "from hermes_cli.profiles import validate_profile_name; import sys; [validate_profile_name(name) for name in sys.argv[1:]]"} \
            ${escapeShellArgs (attrNames active)}
        ''
        + concatStringsSep "\n" (mapAttrsToList setup active)
      )
    );
  };
}
