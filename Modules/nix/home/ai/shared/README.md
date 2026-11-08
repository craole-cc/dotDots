# Shared AI skills and rules

This directory owns reusable skill sources and command policy. Agent modules
adapt them to their supported formats. Profiles, models and identity remain
with the agent or user bot definitions.

Add custom skill Markdown files under `skills/`; both adapters discover them.
The curated source and default selection are defined in `skills/default.nix`.
Curated folders retain their scripts, references and other supporting files.
Codex-specific skill overrides remain in Codex's `skills` option.

Add command prefixes and decisions to `rules/default.nix`. Codex renders native
`prefix_rule` declarations. Hermes maps allow decisions to exact commands and
argument globs in `command_allowlist`, and describes the shared policy in
`AGENTS.md`. Hermes has no equivalent native per-prefix prompt declaration;
prompt decisions are instructions backed by its existing approval checks, not
a claim of Codex-equivalent enforcement. No global approval bypass is enabled.

For Hermes, opt in with `shared.skills.enable` and `shared.rules.enable` in the
bot definition. `shared.skills.curated` overrides the curated selection. These
settings follow host/user schema resolution and are disabled by default.
Craig's root Hermes opts in. Named profiles can reference its installed skills
through `skills.external_dirs`; the user's bot roster owns profile selection.

The AI parent excludes this catalog from automatic Home Manager imports.
Maintainers should run `Tests/nix/ai-shared` and `Tests/nix/hermes` through the
flake before publishing changes. Activation and live agent behavior require
separate verification; no action is taken on runtime homes by these checks.
