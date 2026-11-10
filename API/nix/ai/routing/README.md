# Scheduled provider routes

`default.nix` builds each opted-in bot's policy from its normal model and
explicit offPeakModel. It installs routing-policy.json under that profile's
effective home. Developer, Architect, Intern and Scribe opt in. Top-level
`ai.routing` exposes this constructor; model choices stay with their bot.

Peak periods are 01:00–04:00 and 06:00–10:00 UTC on Chinese working weekdays.
All other hours are off-peak, including ordinary weekends and the supplied
Chinese public holidays; listed make-up workdays follow weekday windows.
The calendar is carried from TheOracle's policy and identifies its official
source in the generated policy. It covers 2026 only. Maintain calendar.json
from the official holiday/workday notice before expiry. Outside coverage or
with invalid policy, the selector chooses Codex, never guesses a discount.

The user selection references the existing private/hermes/deepseek.env using
the central private stem, anchored to the Home Manager home directory. It passes
only the runtime path to opted-in bots. Secret contents never enter the store.
The runtime path is declared unconditionally: pure Nix evaluation cannot see
private files and must not decide whether to install credentials. Activation
reads the declared file at runtime. Ensure it exists before activation; its
contents remain outside the store. If native credentials cannot be resolved,
binding returns to Codex. Explicit profile environment.files
overrides remain available for other credential sources.

The Nix Hermes package adapter patches the filtered Python source used to build
the runtime wheel. No installed files are edited manually. The selector initializes
after the safe primary snapshot and checks before request construction and cache
redecoration. It uses Hermes's native route binder for credentials, clients,
transport, reasoning and compressor state. Native provider fallback remains sticky
for the current turn. A new turn can reevaluate the schedule.

The selected Codex primary must remain available. If neither the selected route
nor the safe primary can bind, stop the request. This feature is a time-based
route selector, not a spending cap or a guarantee of provider availability.

Run Tests/python/test_hermes_scheduled_routes.py and Tests/nix/hermes before
publishing. Run `Tests/python/check_hermes_scheduled_runtime.py` with the built
Hermes venv interpreter to verify installed hooks and native provider binding.
Network-free tests verify timing and binding decisions; paid API
responses still require live acceptance after activation. No deployment is run
by the checks.

## Bounded Workflow Routes

Receptionist and Coordinator use Flash all day for bounded control work, with no
primary fallback. Intern/Scribe use Flash off-peak and Codex Luna at peak.
Developer uses Flash off-peak and Codex Sol at peak; Architect uses DeepSeek Pro
off-peak and Codex Sol at peak. Auditor retains independent Codex review.

`fallback.nix` supplies specialist Flash fallback with the same calendar. The
package adapter filters gated entries at startup and when activating failover;
requests crossing into peak restore the configured primary or stop. Unknown or
expired calendar never authorises discount-dependent Flash fallback. An ongoing
in-flight request cannot be recalled at a clock boundary.

`capabilities.nix` curates skill indexes with the package adapter's optional
`skills.allowed` setting. Essential Hermes skills remain visible and explicit
disabled entries still apply. Architect and Coordinator use `repository_read`,
`skills` and `kanban`; repository_read exposes only read_file and search_files.
Other managed roles get file/terminal/skills/kanban. Named workers do not own
dispatchers or notification subscriptions. Root owns final delivery.

See Documentation/ai/hermes-rebuild/runbook.md for the paused acceptance setup,
activation gate and rollback. Existing sessions and credentials are preserved;
new worker contracts, not session deletion, establish bounded execution.
