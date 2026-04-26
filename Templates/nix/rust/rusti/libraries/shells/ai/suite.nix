{lib}: let
  inherit (lib.shells.ai) mkShell;

  mkSuite = {pkgs ? null}: let
    mk = args: mkShell ({inherit pkgs;} // args);
  in {
    ai = mk {};
    #~@ Entry point
    ai-minimal = mk {
      preset = "minimal";
      includeAnalytics = false;
    };

    #~@ Focused suites
    ai-agents = mk {preset = "agents";};
    ai-assistants = mk {preset = "assistants";};

    #~@ Daily driver
    ai-common = mk {preset = "common";};

    #~@ Full suite — all agents + assistants + analytics + workflow
    ai-full = mk {
      preset = "full";
      includeWorkflow = true;
    };
  };
in {
  inherit mkSuite;
  mkAISuite = mkSuite;
  mkAIShells = mkSuite;
  mkShells = mkSuite;
}
