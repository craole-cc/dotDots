{lix ? (import ../.. {}).libraries.default}: let
  inherit (lix) lib;
  generated = {
    dots-fetch = "/generated/bin/dots-fetch";
    discovered = "/generated/bin/discovered";
    local = "/generated/bin/local";
    ls = "/generated/bin/ls";
  };
  aliasesModule = import ../../Modules/nix/core/environment/aliases.nix {
    config.environment.systemPackages = [];
    host = {};
    top = "_";
    lix =
      lix
      // {
        toolkit = {
          binaries = {};
          commandsFor = _packages: {
            binaries = generated;
            aliases = {
              shortcut = "canonical-shortcut";
              local = "canonical-local";
            };
          };
        };
        modules =
          lix.modules
          // {
            construction =
              lix.modules.construction
              // {
                mkContext = _arguments: {
                  cfg = {
                    default.local = "local-default";
                    extra.local = "local-extra";
                  };
                  resolved.cfg.system.nix.explicit.repo = {};
                };
                mkConfig = specification: specification.outputs;
              };
          };
      };
  };
  evaluated = lib.evalModules {
    modules = [
      {options.environment.shellAliases = lib.mkOption {type = lib.types.attrsOf lib.types.str;};}
      aliasesModule
      {environment.shellAliases.dots-fetch = "fetch /home/craole/.dots";}
      {environment.shellAliases.ls = lib.mkDefault "ls --color=tty";}
      {environment.shellAliases.shortcut = "competing-shortcut";}
    ];
  };
  aliases = evaluated.config.environment.shellAliases;
in {
  explicitDefinitionWinsOverDiscoveredBinary = aliases.dots-fetch == "fetch /home/craole/.dots";
  nixOSDefaultWinsOverDiscoveredBinary = aliases.ls == "ls --color=tty";
  toolkitShortcutIsAuthoritative = aliases.shortcut == "canonical-shortcut";
  discoveredAliasRemains = aliases.discovered == generated.discovered;
  localExtraWins = aliases.local == "local-extra";
}
