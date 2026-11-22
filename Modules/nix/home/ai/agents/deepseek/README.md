# DeepSeek Harness

After running `nhs`, open **DeepSeek Harness** from the application launcher,
or run `deepseek-desktop`. It starts the on-demand `deepseek-web` user service
and opens a dedicated Chromium app window. The service listens on loopback
port 3081 by default, leaving port 3080 available for manual `dsh web` sessions.
The app browser has its own profile under the XDG configuration directory.

Closing the window leaves the backend running. Stop it explicitly with
`systemctl --user stop deepseek-web`. Diagnose startup with
`systemctl --user status deepseek-web`. Its startup log contains the local
authentication URL and lives in the private `$XDG_RUNTIME_DIR/deepseek-web`
directory; do not share it without removing credentials.

The `dsh` command remains available for `headless` and other profiles. Both
launch paths use `credentials.sources`: ordered dotenv files under
`~/Private/deepseek*`, `~/Private/dsh*`, and the XDG `dsh` configuration directory.
Files are read at each backend start. After changing credentials while the
desktop backend is running, stop the service and reopen the app.

Configure `_.resolved.ai.agents.deepseek.defined.desktop.port` or
`desktop.browser` to change the port or Chromium package. This is a launcher
for the Web UI, not the upstream Electron application.

The web profile adds an `openai-codex` provider with the planner, worker and
executor models from `API/nix/ai/model-policy.nix`. DeepSeek remains the default.
DSH keeps its own provider credentials: sign in through its provider settings
after activation. The route does not import Pi's credentials. Other DSH
profiles keep their own provider configuration.
