# Hermes Profiles Workflow

This repository uses Hermes profiles as role-based work modes instead of one profile doing everything.

## Profiles

### default
- Provider/model: OpenAI Codex / gpt-5.4
- Role: fallback everyday profile
- Use when: you want the current default behavior and do not care about role separation

### dev
- Provider/model: OpenAI Codex / gpt-5.4
- Role: implementation and debugging
- Use when:
  - editing Rust or Nix
  - building CLI, desktop, web, or game code
  - debugging, testing, refactoring, and reviewing code
- Good prompts:
  - "Implement this Rust subcommand in Libraries/rust/..."
  - "Debug this Nix module evaluation error"
  - "Refactor this config and run the relevant checks"

### research
- Provider/model: Google Gemini CLI / gemini-3-flash-preview
- Role: learning and architectural exploration
- Use when:
  - comparing frameworks or libraries
  - asking for explanations before coding
  - planning a feature or project structure
  - exploring business/product ideas before implementation
- Good prompts:
  - "Compare Bevy vs Godot for a small educational game"
  - "Explain how to structure a reusable Nix library for this repo"
  - "Teach me the tradeoffs before I build this"

### writing
- Provider/model: Google Gemini CLI / gemini-3-flash-preview
- Role: Typst, education, and business writing
- Use when:
  - drafting Typst documents in VS Code
  - writing Grade 6 PEP lesson plans for Jamaica
  - creating worksheets, outlines, proposals, and website copy
- Good prompts:
  - "Draft a Grade 6 PEP math lesson plan on fractions"
  - "Create a Typst outline for this handout"
  - "Rewrite this service description for parents/schools"

### lab
- Provider/model: OpenRouter / nvidia/nemotron-3-super-120b-a12b:free
- Role: experiments and provider/model trials
- Use when:
  - testing prompts or new workflows
  - trying OpenRouter or future Ollama Cloud setups
  - checking whether an idea is good enough before moving into dev/research/writing
- Good prompts:
  - "Try three prompt variants for this task"
  - "Compare outputs for this same spec"
  - "Prototype a throwaway version before I build it properly"

## Recommended repo workflow

1. Start in `research` when the task is unclear.
2. Move to `dev` when you are ready to implement.
3. Use `writing` for Typst, lesson plans, and outward-facing business content.
4. Use `lab` for experiments you do not want contaminating the serious workflows.

## Nix-flake-friendly usage

Prefer explicit profile selection instead of shell aliases:

```bash
hermes --profile dev
hermes --profile research
hermes --profile writing
hermes --profile lab
```

For one-shot commands from the repo root:

```bash
hermes --profile dev chat -q "debug this Rust build failure"
hermes --profile research chat -q "compare Tauri and egui for this app"
hermes --profile writing chat -q "draft a Grade 6 PEP lesson plan on ecosystems"
hermes --profile lab chat -q "test three low-cost prompt approaches"
```

## Suggested task routing

- `Configuration/`, `Libraries/`, `Modules/`, `Packages/`, `API/`: start in `dev`
- Architecture questions, framework comparisons, learning tasks: start in `research`
- `Templates/` docs, Typst drafts, education/business copy: start in `writing`
- Prompt/model/provider tests and throwaway prototypes: start in `lab`

## Promotion rule

Only promote work upward:
- lab -> research/dev/writing when an experiment proves useful
- research -> dev when a plan is solid
- writing -> dev only when you need automation or generation support

This keeps the expensive/high-focus workflows clean and makes the low-cost profiles do the exploratory work first.
