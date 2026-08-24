{
  pkgs,
  lix,
  print,
  descriptions,
  names,
  ...
}: let
  inherit (pkgs) curl docker gum jq writeScriptBin writeShellApplication;
  inherit (lix.filesystem.access) readFile;

  helpContent = ''
    #!/bin/sh
    set -eu
    ${print.title "Hindsight"}
    ${print.table {
      columns = ["Command" "Description"];
      rows = map (name: [name (descriptions.${name} or "?")]) names;
    }}
  '';

  up = writeShellApplication {
    name = "hindsight-up";
    runtimeInputs = [docker gum];
    text = readFile ./up.sh;
  };

  down = writeShellApplication {
    name = "hindsight-down";
    runtimeInputs = [docker];
    text = readFile ./down.sh;
  };

  logs = writeShellApplication {
    name = "hindsight-logs";
    runtimeInputs = [docker];
    text = readFile ./logs.sh;
  };

  status = writeShellApplication {
    name = "hindsight-status";
    runtimeInputs = [curl];
    text = readFile ./status.sh;
  };

  verify = writeShellApplication {
    name = "hindsight-verify";
    runtimeInputs = [curl jq];
    text = readFile ./verify.sh;
  };

  bankCreate = writeShellApplication {
    name = "hindsight-bank-create";
    runtimeInputs = [docker];
    text = readFile ./bank-create.sh;
  };

  bankList = writeShellApplication {
    name = "hindsight-bank-list";
    runtimeInputs = [docker];
    text = readFile ./bank-list.sh;
  };

  showHelp = writeScriptBin "hindsight-help" helpContent;
in {
  env = {
    HINDSIGHT_COMPOSE_FILE = toString ./compose.yaml;
  };
  packages = [
    up
    down
    logs
    status
    verify
    bankCreate
    bankList
    showHelp
  ];
}
