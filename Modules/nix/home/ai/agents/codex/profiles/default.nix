{
  lix,
  cfg,
  ...
}: let
  inherit (lix.attrsets.transformation) removeNulls;
  inherit (lix.options.construction) mkOption;
  inherit (lix.types.combinators) attrsOf;
  inherit (lix.types.primitives) anything;
in {
  options.profiles = mkOption {
    type = attrsOf anything;
    default = {
      # Read-only second opinion on a change, using the review model.
      review = removeNulls {
        model = cfg.model.review;
        model_reasoning_effort = cfg.reasoning.review;
        approval_policy = "on-request";
        sandbox_mode = "read-only";
      };

      # Hard problems: the review model at maximum reasoning.
      deep = removeNulls {
        model = cfg.model.review;
        model_reasoning_effort = "xhigh";
      };

      # Small edits and questions where speed matters more than depth.
      quick = {
        model_reasoning_effort = "low";
      };

      writing = {
        model = "gpt-6-luna";
        model_reasoning_effort = "low";
        sandbox_mode = "read-only";
        developer_instructions = ''
          Perform only explicitly commissioned writing or editing tasks.
          Follow the supplied brief, scope, voice, and output format strictly.
          Do not implement code, change files, run commands, or delegate work.
          If the brief lacks information needed to finish, ask for it.
        '';
      };
    };
    description = ''
      Named config profiles written to `~/.codex/<name>.config.toml`
      (`programs.codex.profiles`), selected with `codex --profile <name>`.
    '';
  };

  program = {inherit (cfg) profiles;};
}
