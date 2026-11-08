{
  lix,
  homePath,
  ...
}: let
  inherit (lix.filesystem.access) readFile;
in {
  home.file = {
    "SOUL.md" = readFile ../worker-soul.md;
    "home-path.txt" = homePath;
    "skills/example/references/evidence.md" = "Explicit bot override";
  };
  settings.model = {
    provider = "custom";
    default = "local-skill-model";
  };
}
