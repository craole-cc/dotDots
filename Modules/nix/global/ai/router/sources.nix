{pkgsFor, ...}:
(pkgsFor {
  sources = {
    # codex = "llm-agents";
    #gemini-cli = "llm-agents";
    # hermes-agent = "llm-agents";
    openclaw = "llm-agents";
    opencode = "llm-agents";
    #claude-code = "llm-agents";
  };
}).packages
