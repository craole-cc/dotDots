{
  lix,
  cfg,
  ...
}: let
  inherit (lix.attrsets.transformation) removeNulls;
  inherit (lix.options.construction) mkEnum mkFalse mkOption;
  inherit (lix.types.combinators) listOf nullOr;
  inherit (lix.types.primitives) str;
in {
  options = {
    model = {
      main = mkOption {
        type = nullOr str;
        default = "gpt-6.1-sol";
        description = ''
          Model for normal Codex work (`model`). Null leaves the choice to Codex.
        '';
      };
      review = mkOption {
        type = nullOr str;
        default = "gpt-6.1-sol";
        description = ''
          Model for the `/review` command (`review_model`).
          Does not affect auto-review approval decisions.
        '';
      };
    };

    reasoning = {
      main = mkEnum {
        input = ["low" "medium" "high"];
        default = "low";
        description = ''Reasoning effort for normal work (`model_reasoning_effort`).'';
      };
      review = mkEnum {
        input = ["low" "medium" "high"];
        default = "medium";
        description = ''Reasoning effort for the review profile.'';
      };
      planning = mkEnum {
        input = ["low" "medium" "high"];
        default = "high";
        description = ''Reasoning effort in Plan mode (`plan_mode_reasoning_effort`).'';
      };
    };

    approval = {
      policy = mkEnum {
        input = ["on-request" "on-failure" "never"];
        default = "on-request";
        description = ''
          When Codex pauses to ask before acting (`approval_policy`).
          Auto-review needs an interactive policy such as on-request; with never there is nothing to review.
        '';
      };
      reviewer = mkEnum {
        input = ["user" "auto_review"];
        default = "auto_review";
        description = ''
          Who handles eligible approval prompts (`approvals_reviewer`):
          the user (you), or the separate auto-review agent.
        '';
      };
    };

    sandbox = {
      mode = mkEnum {
        input = ["read-only" "workspace-write" "danger-full-access"];
        default = "workspace-write";
        description = ''What Codex may touch on disk (`sandbox_mode`).'';
      };
    };

    update = {
      check = mkFalse ''
        Whether Codex checks for updates on startup (`check_for_update_on_startup`).
        Off by default because Nix pins the package.
      '';
    };

    tui = {
      notifications = mkOption {
        type = nullOr (listOf str);
        default = ["agent-turn-complete" "approval-requested"];
        description = ''
          Events that trigger a terminal notification (`tui.notifications`).
        '';
      };
      condition = mkEnum {
        input = ["unfocused" "always"];
        default = "unfocused";
        description = ''
          When notifications fire (`tui.notification_condition`).
        '';
      };
    };
  };

  settings = removeNulls {
    model = cfg.model.main;
    review_model = cfg.model.review;
    model_reasoning_effort = cfg.reasoning.main;
    plan_mode_reasoning_effort = cfg.reasoning.planning;
    approval_policy = cfg.approval.policy;
    approvals_reviewer = cfg.approval.reviewer;
    sandbox_mode = cfg.sandbox.mode;
    check_for_update_on_startup = cfg.update.check;
    tui = removeNulls {
      notifications = cfg.tui.notifications;
      notification_condition = cfg.tui.condition;
    };
  };
}
