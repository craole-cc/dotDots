# AI catalog

This directory owns bot definitions, shared skills and shared command policy.
Agent modules adapt the selected definitions to their runtime formats. Host and
user records select bots and override configuration; the catalog never selects
an active host or user.

- `bots/<name>/` owns default.nix, SOUL.md, AGENTS.md and optional local skills.
- `skills/` owns reusable skill sources and curated references.
- `rules/` owns reusable structured command policy.
- `routing/` owns the off-peak schedule/calendar constructor; each bot owns its model choices.

`mkSchema` exposes the explicit `ai/default.nix` catalog without passing its
functions and rule lists through the generic identity-record walker. The Hermes
bot loader takes an explicit enabled list and optional definition overrides.
The `receptionist` catalog definition is selected as `default` downstream.
Hermes maps it to root/default, never a named `receptionist` profile.

A bot's `skills/<skill>/` tree is installed only into that bot's runtime skills
directory, including scripts, references and other supporting files. Explicit
home.file entries override discovered local skill files. Named Hermes profiles
also discover the root shared skills through external_dirs.

Add custom skill Markdown files under `skills/`; the agent adapters discover them.
The curated source and default selection are defined in `skills/default.nix`.
Curated folders retain their scripts, references and other supporting files.
Codex-specific skill overrides remain in Codex's `skills` option.

Enabled Pi and DeepSeek Harness modules receive the same custom and default
curated skills in `~/.pi/agent/skills/` and `~/.dsh/skills/`. Complete skill bundles
remain linked with their references, scripts and assets. Their native global
`AGENTS.md` files also receive shared command-policy instructions and guidance
to load the relevant skills. Pi's `grep` and `find` tool names use `rg` and `fd`;
shell commands still follow the shared `sh-utils` skill. Super+A launches plain
Pi and inherits these files without special terminal flags.

Add command prefixes and decisions to `rules/default.nix`. `rules/render.nix`
adapts that one list for each runtime. Codex renders native
`prefix_rule` declarations. Hermes maps allow decisions to exact commands and
argument globs in `command_allowlist`, and describes the shared policy in
`AGENTS.md`. Hermes has no equivalent native per-prefix prompt declaration;
prompt decisions are instructions backed by its existing approval checks, not
a claim of Codex-equivalent enforcement. No global approval bypass is enabled.
Pi and DeepSeek receive policy as instructions; their native runtime approvals
remain authoritative. Tool implementations and live MCP connections remain
runtime-specific and are not copied from Codex by this catalog.

For Hermes, opt in with `shared.skills.enable` and `shared.rules.enable` in the
bot definition. `shared.skills.curated` overrides the curated selection. These
settings follow host/user schema resolution and are disabled by default.
Craig's root Hermes opts in. Named profiles can reference its installed skills
through `skills.external_dirs`; the user's bot roster owns profile selection.

The catalog is API data, not a Home Manager module.
Maintainers should run `Tests/nix/ai-shared` and `Tests/nix/hermes` through the
flake before publishing changes. Activation and live agent behavior require
separate verification; no action is taken on runtime homes by these checks.
