{lix, ...} @ args: let
  inherit (lix.attrsets.access) attrNames;

  descriptions = {
    hindsight-up = "Start the Hindsight service";
    hindsight-down = "Stop the Hindsight service";
    hindsight-logs = "Follow Hindsight container logs";
    hindsight-status = "Check Hindsight API health";
    hindsight-verify = "Validate the Hindsight OpenAPI document";
    hindsight-bank-create = "Create a Hindsight memory bank";
    hindsight-bank-list = "List Hindsight memory banks";
    hindsight-help = "Show this help";
  };

  names = attrNames descriptions;

  scripts = import ./scripts (args // {inherit descriptions names;});
in {inherit descriptions names scripts;}
