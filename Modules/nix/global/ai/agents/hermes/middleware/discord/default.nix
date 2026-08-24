args: let
  inherit (args) lix;
  inherit (lix.strings.transformation) escapeShellArg;
in {
  prepare-discord-gateway = ''
    export HERMES_DISCORD_BOT_TOKEN="${escapeShellArg (builtins.getEnv "DISCORD_BOT_TOKEN" "")}"
    export HERMES_DISCORD_ALLOWED_USERS="${escapeShellArg (builtins.getEnv "DISCORD_ALLOWED_USERS" "")}"
    export HERMES_DISCORD_HOME_CHANNEL="${escapeShellArg (builtins.getEnv "DISCORD_HOME_CHANNEL" "")}"
    export HERMES_DISCORD_HOME_CHANNEL_NAME="${escapeShellArg (builtins.getEnv "DISCORD_HOME_CHANNEL_NAME" "Home")}"
  '';
}