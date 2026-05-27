env_file="$HERMES_HOME/.env"
mkdir -p "$HERMES_HOME"
touch "$env_file"

env_get() {
  key="$1"
  sed -n "s/^${key}=//p" "$env_file" | tail -n 1
}

env_set() {
  key="$1"
  value="$2"
  python "$HERMES_ENV_PY" "$env_file" "$key" "$value"
}
