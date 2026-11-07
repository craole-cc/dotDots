{lix, ...}: let
  inherit (lix.filesystem.access) readFile;
in {
  description = "Bot wiring fixture";
  home.file = {
    "SOUL.md" = readFile ./worker-soul.md;
    "skills/example/SKILL.md" = readFile ./worker-skill.md;
  };
  settings.model = {
    provider = "custom";
    default = "fixture-model";
  };
}
