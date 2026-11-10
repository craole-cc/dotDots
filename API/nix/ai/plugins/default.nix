{lix, ...}: let
  inherit (lix.toolkit.builders) runCommand;
  inherit (lix.toolkit.fetch) fromGitHub;
  revision = "13b2c1c9c8204bf333df240b2aacf98c3e6250b7";
  source = fromGitHub {
    owner = "NousResearch";
    repo = "hermes-official-plugins";
    rev = revision;
    hash = "sha256-TrGVFnS8CFy3DhDEr/Oc1zrkjxhHlJ0mqj0Xk5aEcjc=";
  };
in {
  advanced-delegation =
    runCommand "advanced-delegation" {
      pname = "advanced-delegation";
      version = "1.1.0";
      passthru = {inherit revision;};
    } ''
      mkdir -p "$out"
      cp -R ${source}/advanced-delegation/. "$out/"
    '';
}
