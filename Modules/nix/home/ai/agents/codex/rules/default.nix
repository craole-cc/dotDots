{
  lix,
  cfg,
  ...
}: let
  inherit (lix.schema.construction) mkSchema;
  shared = (mkSchema {}).ai.rules;
  inherit (lix.strings.construction) concatStringsSep toJSON;
  inherit (lix.options.construction) mkOption;
  inherit (lix.types.combinators) attrsOf either;
  inherit (lix.types.primitives) lines path;
in {
  options.rules = mkOption {
    type = attrsOf (either lines path);
    default.common = concatStringsSep "\n" (map (rule: "prefix_rule(pattern = ${toJSON rule.pattern}, decision = ${toJSON rule.decision})") shared);
    description = ''
      Command prefix rules, one file per name under `~/.codex/rules/`
      (`programs.codex.rules`). Add your own as extra names, such as
      `rules.work`, and they merge with the common set.
    '';
  };

  program = {inherit (cfg) rules;};
}
