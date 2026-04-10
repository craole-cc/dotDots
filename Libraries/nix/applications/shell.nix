# sections/shell.nix
{helpers, byCategory}: let
  inherit (helpers) mkSection mkBoolQueries normalizeConfig filterAttrs;
  all = byCategory.shell;
in {
  inherit all;

  shells = mkSection {
    set = normalizeConfig {
      set = filterAttrs (_: a: (a.categories or []) == ["shell"]) all;
    };
    grouped      = {member = ["engine"]; fields = ["config" "maturity"];};
    # posix split runs on the full shell set, not the filtered-to-pure-shell subset
    extraQueries = _: mkBoolQueries {
      set      = all;
      field    = "posix";
      trueKey  = "posix";
      falseKey = "modern";
    };
  };

  prompts = mkSection {
    set        = byCategory.prompt;
    grouped    = {eq = ["engine"]; member = ["shells"]; fields = ["maturity"];};
    queryField = "shells";
  };

  enhancements = mkSection {
    set          = byCategory.enhancement;
    grouped      = {eq = ["kind"]; member = ["shells" "engine"]; fields = ["maturity"];};
    queryField   = "shells";
    extraQueries = groups: {inherit (groups.byKind) history fuzzy navigation;};
  };

  lineEditors = mkSection {
    set        = byCategory."line-editor";
    grouped    = {member = ["engine" "shell"]; fields = ["maturity"];};
    queryField = "shells";
  };
}
