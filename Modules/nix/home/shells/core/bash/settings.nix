{
  historyControl = ["ignoreboth"];

  # Tools such as dsh take provider keys from the environment, and this shell aliases
  # every discovered binary straight to its store path, so a wrapper function would
  # never be reached. The key stays in a private file and is loaded once at start.
  initExtra = ''
    if [ -r "$HOME/Private/deepseek.env" ]; then
      set -a
      . "$HOME/Private/deepseek.env"
      set +a
    fi
  '';
}
