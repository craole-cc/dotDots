---
name: nix-inspect
description: Inspect evaluated Nix and Home Manager configuration without building or deploying. Use when debugging option values, merges, or generated files.
---

# Inspecting Nix configuration

- **Interactive REPL:** Print an evaluated option in `nix repl` with `:p config.<path>`.
- **Derivations:** Derivations print as `«derivation ...»`, which cannot be pasted back as valid syntax.
- **Generated files:** To read generated file contents, inspect `lix.strings.readFile <attribute>.source`.
- **Store paths:** Remember store paths may not exist on disk until built.
- **Quick checks:** Prefer `nix eval` for quick, one-off evaluation checks.
- **Safety guardrail:** Never run `switch`, `boot`, `test`, or `deploy` commands automatically; request user execution.
