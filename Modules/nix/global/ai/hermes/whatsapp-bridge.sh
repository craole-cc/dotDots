bridge_src="$HERMES_WHATSAPP_BRIDGE_SRC"
bridge_dir="${HERMES_WHATSAPP_BRIDGE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/hermes/whatsapp-bridge}"
bridge_script="$bridge_dir/bridge.js"
gateway_json="$HERMES_HOME/gateway.json"

mkdir -p "$bridge_dir" "$HERMES_HOME"

cp -f \
  "$bridge_src/allowlist.js" \
  "$bridge_src/allowlist.test.mjs" \
  "$bridge_src/bridge.js" \
  "$bridge_src/package.json" \
  "$bridge_src/package-lock.json" \
  "$bridge_dir/"

if [ ! -d "$bridge_dir/node_modules" ] \
  || [ "$bridge_src/package-lock.json" -nt "$bridge_dir/node_modules" ]
then
  gum log --level info "Installing WhatsApp bridge dependencies in $bridge_dir"
  (
    cd "$bridge_dir" || exit 1
    npm ci --no-fund --no-audit --progress=false >/dev/null
  )
fi

python "$HERMES_WHATSAPP_GATEWAY_PY" "$gateway_json" "$bridge_script"
