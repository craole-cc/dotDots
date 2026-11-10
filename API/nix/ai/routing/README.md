# Scheduled provider routes

`default.nix` builds each opted-in bot's policy from its normal model and
explicit offPeakModel. It installs routing-policy.json under that profile's
effective home. Only Developer and Architect opt in. Top-level
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

## Routine Roles And Codex Quota

Receptionist, Coordinator, Intern and Scribe import `routine.nix`: DeepSeek Flash
at all hours, scheduled switching disabled, and no primary fallback. Auxiliary
slots are explicitly pinned to DeepSeek Flash with no configured fallback chain,
so automatic provider discovery cannot choose Codex when DeepSeek fails. A task
requiring an unsupported capability must report the limitation rather than change
providers. These roles receive the same runtime credentials file as the other bots.
Developer, Architect and Auditor retain their existing routes and reasoning.

Coordinator commissions whole packages and uses bounded evidence retrieval under
`bots/POLICY.md`. Receptionist's fixed concise directive lives at the top of its
SOUL.md; Coordinator, Intern and Scribe select `terse.level = "lite"`. These
instructions preserve required code, validation and independent review findings.

Token cache hits reduce repeated input processing; they do not eliminate input
cost or establish how ChatGPT Plus allowance is charged. Local session counters
can omit auxiliary calls/retries and can combine route changes under one session
label. Use provider billing for money and the ChatGPT usage display for allowance;
do not infer a quota-saving percentage from cached-token ratios.

After the owner activates with `nhs`, verify the effective gateway home and model
settings in a fresh chat before paid acceptance. Existing conversations retain
their history and may retain session-specific model choices. No activation or
provider request is performed by the offline checks.
