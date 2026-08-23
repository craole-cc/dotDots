args: let
  inherit (args) lix;
  inherit (lix.filesystem.access) readFile;
  inherit (lix.strings.transformation) escapeShellArg;
in {
  prepare-telegram-gateway = ''
    export HERMES_TELEGRAM_BOT_TOKEN="${escapeShellArg (builtins.getEnv "TELEGRAM_BOT_TOKEN" "")}"
    export HERMES_TELEGRAM_ALLOWED_USERS="${escapeShellArg (builtins.getEnv "TELEGRAM_ALLOWED_USERS" "")}"
    export HERMES_TELEGRAM_HOME_CHANNEL="${escapeShellArg (builtins.getEnv "TELEGRAM_HOME_CHANNEL" "")}"
    export HERMES_TELEGRAM_HOME_CHANNEL_NAME="${escapeShellArg (builtins.getEnv "TELEGRAM_HOME_CHANNEL_NAME" "Home")}"
  '';
}
