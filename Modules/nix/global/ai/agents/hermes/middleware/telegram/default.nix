# TODO: This is not the right way: using builtins.getEnv is not a good idea, because it will not work in all contexts. We should use a more robust way to pass the environment variables to the script.
args: let
  inherit (args) lix;
  inherit (lix.strings.transformation) escapeShellArg;
in {
  prepare-telegram-gateway = ''
    export HERMES_TELEGRAM_BOT_TOKEN="${escapeShellArg (builtins.getEnv "TELEGRAM_BOT_TOKEN" "")}"
    export HERMES_TELEGRAM_ALLOWED_USERS="${escapeShellArg (builtins.getEnv "TELEGRAM_ALLOWED_USERS" "")}"
    export HERMES_TELEGRAM_HOME_CHANNEL="${escapeShellArg (builtins.getEnv "TELEGRAM_HOME_CHANNEL" "")}"
    export HERMES_TELEGRAM_HOME_CHANNEL_NAME="${escapeShellArg (builtins.getEnv "TELEGRAM_HOME_CHANNEL_NAME" "Home")}"
  '';
}
