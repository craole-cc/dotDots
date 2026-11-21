{lix, ...}: let
  inherit (lix.lists.aggregation) concatMap;
  inherit (lix.lists.transformation) filter;
  inherit (lix.strings.construction) concatStringsSep toJSON;

  rules = import ./default.nix;
  command = rule: concatStringsSep " " rule.pattern;
  allowed = filter (rule: rule.decision == "allow") rules;
  describe = rule:
    if rule.decision == "prompt"
    then "- Ask for approval before running `${command rule}` or that command with additional arguments."
    else if rule.decision == "allow"
    then "- `${command rule}` and that command with additional arguments need no command approval prompt."
    else if rule.decision == "forbidden"
    then "- Do not run `${command rule}` or that command with additional arguments."
    else throw "Unsupported shared command decision: ${rule.decision}";
in {
  codex = concatStringsSep "\n" (map (rule: "prefix_rule(pattern = ${toJSON rule.pattern}, decision = ${toJSON rule.decision})") rules);
  allowlist = concatMap (rule: [(command rule) "${command rule} *"]) allowed;
  instructions = {
    runtime,
    enforcement ? "These entries are workflow instructions, not native prefix-rule enforcement. Keep ${runtime}'s native approval checks enabled.",
  }: ''
    # Shared command policy

    These rules express command approval policy, not permission to start work
    or publish changes without the user's task authorisation. Follow applicable
    repository instructions and relevant skills before acting.

    ${concatStringsSep "\n" (map describe rules)}

    ${enforcement}

    Use the relevant installed skills. For repository changes read plan-first;
    for Nix edits read nix-style; for commits read commit-messages. Apply
    writing-style to prose and sh-utils to shell inspection. Use nix-inspect
    for configuration evaluation.
  '';
}
