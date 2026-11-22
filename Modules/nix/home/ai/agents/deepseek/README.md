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
DSH 0.2.2-rc.5 does not expose Codex OAuth in Models settings.

## Open Harness and Chat together

On Niri, press **Super+Shift+Alt+A** or run `deepseek-workspace` to launch
Harness and the official DeepSeek Chat site as separate app windows. Run
`deepseek-chat` to open Chat by itself. Chat keeps its browser session in
its own Chromium profile.

## Sign in to ChatGPT for Codex

1. After deploying this configuration, run `deepseek-codex-login` in a local
   terminal as the same user that runs the desktop app. The command and service
   must resolve the same DSH home (normally `~/.dsh`).
2. Open the sign-in URL shown in the terminal and follow the browser prompts.
   If the terminal asks for a callback URL or code, paste it there and press
   Enter. Input is hidden. Ctrl+C cancels the attempt.
3. When the terminal reports success, reopen DeepSeek Harness. If its backend
   is still running and does not pick up the grant, run
   `systemctl --user stop deepseek-web` and reopen the app. Select an
   `openai-codex` model in the picker.

The helper runs DSH's built-in OAuth flow. DSH stores the grant in its own
credential store under `llm-pi-ai/openai-codex`.
