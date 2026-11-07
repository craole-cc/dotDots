{
  cfg,
  common,
  config,
  interface,
  entryBetween,
  lix,
  pkgs,
  runtime,
  resolve,
  validator,
  isValidProfileName,
  ...
}: let
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.attrsets.transformation) filterAttrs mapAttrsToList;
  inherit (lix.filesystem.construction) concatPath;
  inherit (lix.lists.aggregation) concatMap;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.modules.construction) mkIf mkLayer;
  inherit (lix.options.construction) mkEnum mkFalse mkOption mkTrue;
  inherit (lix.strings.construction) concat optionalString toJSON;
  inherit (lix.strings.transformation) escapeShellArg escapeShellArgs;
  inherit (lix.types.combinators) attrsOf nullOr submodule;
  inherit (lix.types.primitives) str;
  inherit (lix.toolkit) write;
  inherit (runtime) binaries;

  #~@ Providers that require an explicit auth.file or environment.files entry.
  #? Profiles do not inherit the main profile's credentials.
  cloudProviders = [
    "anthropic"
    "openai"
    "openai-codex"
    "openrouter"
    "google"
    "mistral"
  ];

  #~@ Terse output directives
  #? Prepended to SOUL.md so they sit at the stable top of the prompt, which
  #? keeps provider prompt caching effective. Output tokens shrink; the
  #? directive itself costs a few input tokens per turn, so keep it short.
  terseDirectives = {
    off = "";
    lite = "Be concise. No filler, no pleasantries, no restating the question.";
    full = ''
      Respond terse. Drop articles, filler and hedging. Fragments are fine.
      Keep code, paths, commands and error text exact.
      Use normal prose for security warnings and destructive-action confirmations.
    '';
  };

  terseOptions = {
    terse.level = mkEnum {
      input = ["off" "lite" "full"];
      default = "off";
      description = "Output terseness directive prepended to this profile's SOUL.md.";
    };
  };

  #? SOUL.md may be declared as a string or a path; normalise to text before
  #? prepending. The directive is a no-op when the level is "off", so profiles
  #? that do not opt in keep their declared SOUL.md untouched.
  withTerseSoul = profile: let
    directive = terseDirectives.${profile.terse.level};
    declaredSoul = profile.home.file."SOUL.md" or "";
    soulText =
      if builtins.isPath declaredSoul
      then builtins.readFile declaredSoul
      else declaredSoul;
  in
    if directive == ""
    then profile
    else
      profile
      // {
        home =
          profile.home
          // {
            file =
              profile.home.file
              // {
                "SOUL.md" = concat "\n\n" [directive soulText];
              };
          };
      };

  botOptions = name: {
    bot = mkOption {
      description = "Bot Mode presentation and a launcher for the profile's persistent Bot Chat.";
      default = {};
      type = submodule {
        options = {
          enable = mkFalse "Present this profile as a named Bot in Hermes Desktop.";
          title = mkOption {
            type = str;
            default = name;
            description = "Display name in the Hermes Bot roster.";
          };
        };
      };
    };
  };

  botMetadata = _name: profile: {
    ui_meta.hermes-bots =
      if profile.bot.enable
      then {inherit (profile.bot) title;}
      else null;
  };

  service = config.services.hermes-agent;
  active = filterAttrs (_name: profile: profile.enable) cfg.profiles;
  upstreamOptions = common.sharedOptions {
    defaultPackage = service.package;
    defaultPackageText = "services.hermes-agent.package";
    defaultWorkingDirectory = service.workingDirectory;
    defaultWorkingDirectoryText = "services.hermes-agent.workingDirectory";
  };
  profileOptions = {inherit (upstreamOptions) settings environment environmentFiles authFile authFileForceOverwrite documents hermesHomeFiles mcpServers extraPlugins;};
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

  setup = name: declaredProfile: let
    #? Apply the terse directive before any renderer reads home.file.
    profile = withTerseSoul declaredProfile;
    resolved = profileConfig profile;
    homePath = concatPath {
      root = cfg.home.path;
      stem = ["profiles" name];
    };
    profileFile = escapeShellArg (concatPath {
      root = homePath;
      stem = "profile.yaml";
    });
    metadata = pkgs.writeText "hermes-${name}-metadata.json" (toJSON (
      optionalAttrs (profile.description != null) {
        inherit (profile) description;
        description_auto = false;
      }
      // botMetadata name profile
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
    $DRY_RUN_CMD ${mergeScript} ${metadata} ${profileFile}
    $DRY_RUN_CMD chmod 0600 ${profileFile}
  '';
  defaults = {
    profiles = {};
    strictProfileValidation = false;
  };
  resolved = resolve defaults;
in {
  inherit defaults;
  resolutions = mkLayer 1000 {inherit (resolved) profiles strictProfileValidation;};
  #? The runtime validator is a ~2 ms compiled binary, so the reason to disable
  #? it (Python spawn cost) no longer applies. Left default = false to preserve
  #? existing activation timing; flip to mkTrue if you want it every rebuild.
  options.strictProfileValidation = mkFalse ''
    Run the compiled Hermes profile-name validator during activation.
    The validator is a ~2ms Rust binary with no Python dependency, so
    enabling this is cheap. The Nix-side regex assertion still runs
    regardless and catches malformed names at eval time.
  '';

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
        // botOptions name
        // terseOptions;
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
    home.packages = mapAttrsToList (name: _profile:
      write.binWith "hermes-bot-${name}" [runtime.package] ''
        export HERMES_HOME=${escapeShellArg cfg.home.path}
        exec ${binaries.hermesProfile} ${escapeShellArg name} \
          chat -c ${escapeShellArg "Bot Chat: ${name}"} --create-if-missing "$@"
      '')
    (filterAttrs (_name: profile: profile.bot.enable) active);

    assertions = concatMap (name: let
      profile = active.${name};
      provider = profile.settings.model.provider or "";
    in
      [
        {
          assertion = isValidProfileName name;
          message = "Hermes profile '${name}' needs a lowercase profile name of at most 64 characters; configure default through settings.";
        }
        {
          assertion = profile.documents == {} || profile.workingDirectory != null;
          message = "Hermes profile '${name}' documents require an explicit workingDirectory.";
        }
        {
          assertion =
            profile.documents
            == {}
            || profile.workingDirectory == null
            || profile.workingDirectory
            != concatPath {
              root = cfg.home.path;
              stem = ["profiles" name];
            };
          message = "Hermes profile '${name}' cannot use its home.path as workingDirectory while declaring documents; paths would collide.";
        }
        {
          assertion =
            !(isIn provider cloudProviders)
            || profile.auth.file != null
            || profile.environment.files != [];
          message = "Hermes profile '${name}' uses provider '${provider}' but declares neither auth.file nor environment.files. Profiles do not inherit the main profile's credentials.";
        }
      ]
      ++ common.pluginNameAssertions {
        cfg = interface.config profileOptions profile;
        optionPath = "Hermes profiles.${name}";
      }) (attrNames active);

    home.activation.hermesProfiles = mkIf (active != {}) (
      entryBetween ["reloadSystemd"] ["hermesAgentSetup"] (
        (optionalString cfg.strictProfileValidation ''
          $DRY_RUN_CMD ${validator.command} ${
            escapeShellArgs (attrNames active)
          }
        '')
        + concat "\n" (mapAttrsToList setup active)
      )
    );
  };
}
