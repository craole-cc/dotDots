{
  pkgs,
  lix,
  env,
  descriptions,
  helpTable,
  ...
}: let
  inherit (pkgs) curl docker gum jq writeScriptBin writeShellApplication;
  inherit (lix.filesystem.access) readFile;
  inherit (lix.strings.transformation) escapeShellArg;
  inherit (env) name prefix;

  env' = {
    "${prefix}_COMPOSE_FILE" = escapeShellArg ./compose.yaml;
  };

  helpContent = ''
    #!/bin/sh
    set -eu
    ${helpTable}
  '';

  up = writeShellApplication {
    name = "${name}-up";
    runtimeInputs = [docker gum];
    text = readFile ./up.sh;
  };

  down = writeShellApplication {
    name = "${name}-down";
    runtimeInputs = [docker];
    text = readFile ./down.sh;
  };

  logs = writeShellApplication {
    name = "${name}-logs";
    runtimeInputs = [docker];
    text = readFile ./logs.sh;
  };

  status = writeShellApplication {
    name = "${name}-status";
    runtimeInputs = [curl gum];
    text = readFile ./status.sh;
  };

  verify = writeShellApplication {
    name = "${name}-verify";
    runtimeInputs = [curl jq];
    text = readFile ./verify.sh;
  };

  bankCreate = writeShellApplication {
    name = "${name}-bank-create";
    runtimeInputs = [docker];
    text = readFile ./bank-create.sh;
  };

  bankList = writeShellApplication {
    name = "${name}-bank-list";
    runtimeInputs = [docker];
    text = readFile ./bank-list.sh;
  };

  showHelp = writeScriptBin "${name}-help" helpContent;
in {
  env = env';
  packages = [
    # docker
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
