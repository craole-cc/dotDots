{lix ? (import ../.. {}).libraries.default}: let
  inherit (lix) lib;
  generated = {
    dots-fetch = "/generated/bin/dots-fetch";
    discovered = "/generated/bin/discovered";
    local = "/generated/bin/local";
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
          binariesFor = _packages: generated;
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
    ];
  };
  aliases = evaluated.config.environment.shellAliases;
in {
  explicitDefinitionWins = aliases.dots-fetch == "fetch /home/craole/.dots";
  discoveredAliasRemains = aliases.discovered == generated.discovered;
  localExtraWins = aliases.local == "local-extra";
}
