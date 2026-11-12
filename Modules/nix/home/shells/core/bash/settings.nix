{
  historyControl = ["ignoreboth"];

  # dsh takes its DeepSeek key from the environment, and the key lives in a private
  # file rather than in the store. Hand it to that one command instead of exporting
  # it into every process the shell starts.
  initExtra = ''
    dsh() {
      local key name value
      key="$DEEPSEEK_API_KEY"
      if [ -z "$key" ] && [ -r "$HOME/Private/deepseek.env" ]; then
        while IFS='=' read -r name value; do
          if [ "$name" = "DEEPSEEK_API_KEY" ]; then
            key="$value"
            break
          fi
        done < "$HOME/Private/deepseek.env"
      fi
      if [ -z "$key" ]; then
        echo "dsh: no DEEPSEEK_API_KEY; write it to $HOME/Private/deepseek.env" >&2
        return 1
      fi
      DEEPSEEK_API_KEY="$key" command dsh "$@"
    }
  '';
}
