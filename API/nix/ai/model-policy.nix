# Shared Codex model assignments for agent roles.
{
  planner = {
    model = "gpt-6.2-sol";
    effort = "medium";
  };
  worker = {
    model = "gpt-6.1-terra";
    effort = "medium";
  };
  executor = {
    model = "gpt-6-luna";
    effort = "high";
  };
}
