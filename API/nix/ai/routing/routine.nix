{lix, ...}: let
  inherit (lix.attrsets.construction) genAttrs;
in {
  model = {
    provider = "deepseek";
    default = "deepseek-flash";
  };
  scheduled_routes.enabled = false;
  fallback_providers = [];
  fallback_model = null;
  # Keep auxiliary auto-discovery from using Codex when DeepSeek is unavailable.
  auxiliary =
    genAttrs [
      "approval"
      "compression"
      "curator"
      "kanban_decomposer"
      "mcp"
      "profile_describer"
      "session_search"
      "skills_hub"
      "title_generation"
      "triage_specifier"
      "tts_audio_tags"
      "vision"
      "web_extract"
    ] (_task: {
      provider = "deepseek";
      model = "deepseek-flash";
      fallback_chain = [];
    });
}
