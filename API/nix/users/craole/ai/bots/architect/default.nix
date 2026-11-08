{
  lix,
  homePath,
  ...
}: let
  inherit (lix.filesystem.access) readFile;
in {
  description = "Provide difficult planning and architectural analysis within restricted tools.";
  auth.file = "${homePath}/auth.json";
  home.file = {
    "SOUL.md" = readFile ./SOUL.md;
    "AGENTS.md" = readFile ../POLICY.md;
  };
  settings = {
    model = {
      provider = "openai-codex";
      default = "gpt-6.1-sol";
    };
    agent = {
      max_turns = 100;
      disabled_toolsets = ["terminal" "file" "code_execution" "browser" "computer_use" "delegation" "kanban" "cronjob" "memory" "skills" "todo" "session_search" "image_gen" "video_gen" "bfl" "tts" "stt" "video" "x_search" "homeassistant" "spotify" "discord" "discord_admin" "yuanbao" "project" "context_engine"];
      reasoning_effort = "high";
    };
    skills.external_dirs = ["${homePath}/skills"];
  };
}
