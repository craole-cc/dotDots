# shellcheck shell=sh
#shellcheck enable=all
env_file="$HERMES_HOME/.env"

if [ -L "$env_file" ]; then
  printf '%s\n' "Refusing non-regular Hermes environment file: $env_file" >&2
  exit 1
elif [ -e "$env_file" ]; then
  if [ ! -f "$env_file" ]; then
    printf '%s\n' "Refusing non-regular Hermes environment file: $env_file" >&2
    exit 1
  fi

  owner="$(stat -c '%u' "$env_file")"
  mode="$(stat -c '%a' "$env_file")"
  if [ "$owner" != "$(id -u)" ] || [ $((0$mode & 077)) -ne 0 ]; then
    printf '%s\n' "Refusing Hermes environment file not owned and private to this user: $env_file" >&2
    exit 1
  fi
else
  umask 077
  mkdir -p "$HERMES_HOME"
  : > "$env_file"
  chmod 600 "$env_file"
fi

env_get() {
  key="$1"
  sed -n "s/^${key}=//p" "$env_file" | tail -n 1
}

env_set() {
  key="$1"
  value="$2"
  python "$HERMES_ENV_PY" "$env_file" "$key" "$value"
}
