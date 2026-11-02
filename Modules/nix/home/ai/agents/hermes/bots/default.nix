{
  cfg,
  lix,
  runtime,
  ...
}: let
  inherit (lix.attrsets.transformation) filterAttrs mapAttrsToList;
  inherit (lix.options.construction) mkFalse mkOption;
  inherit (lix.strings.transformation) escapeShellArg;
  inherit (lix.toolkit) write;
  inherit (lix.types.combinators) submodule;
  inherit (lix.types.primitives) str;
  inherit (runtime) binaries;

  active = filterAttrs (_name: profile: profile.enable && profile.bot.enable) cfg.profiles;
in {
  profileOptions = name: {
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

  metadata = _name: profile: {
    ui_meta.hermes-bots =
      if profile.bot.enable
      then {inherit (profile.bot) title;}
      else null;
  };

  outputs = {
    # TODO: Should this be write.binWith?
    home.packages = mapAttrsToList (name: _profile:
      write.bin "hermes-bot-${name}" ''
        export HERMES_HOME=${escapeShellArg cfg.home.path}
        exec ${binaries.hermesProfile} ${escapeShellArg name} \
          chat -c "Bot Chat" --create-if-missing "$@"
      '')
    active;
  };
}
