{
  lix,
  pkgsFor,
  HOME ? "/home/craole",
  ...
}: let
  inherit (lix.strings.transformation) escapeShellArg;

  description = "Hermes Agent";

  env = {
    inherit
      AUTO_START
      HERMES_ENV_PY
      HERMES_ENV_SH
      HERMES_HOME
      STARTUP_TIMEOUT
      ;
  };

  utils = pkgsFor {
    sources = {
      desktop = {
        input = "hermes-agent";
        description = "Official Desktop Interface";
      };
      minimal = {
        input = "hermes-agent";
        description = "Official Agent CLI";
      };
      tui = {
        input = "hermes-agent";
        description = "Official Terminal Interface";
      };
      hermes-hud = {
        input = "llm-agents";
        description = "Community-powered Terminal Interface for status / memory monitoring";
      };
      hermes-one = {
        input = "llm-agents";
        description = "Community-powered Desktop Interface";
      };
    };
  };

  AUTO_START = 0;
  STARTUP_TIMEOUT = 15;
  HERMES_HOME = HOME + "/.hermes";
  HERMES_ENV_PY = escapeShellArg ./env.py;
  HERMES_ENV_SH = escapeShellArg ./env.sh;
in
  utils // {inherit description env;}
