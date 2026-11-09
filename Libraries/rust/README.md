# Rust scripts

Run `xin` to manage the dotfiles flake. `bin/xin` is an executable entry point
on the repository's existing PATH; it runs `src/xin.rs` through `rust-script`.
It works before system activation. The NixOS configuration also installs a
self-contained `bin/xin` wrapper in the system profile. Run `xin --help` for usage.

```sh
xin --check                  # nix flake check, with --show-trace
xin --clean                  # nh clean all
xin --update                 # Update all flake inputs
xin --update hermes          # Update Hermes and its saved release metadata
xin --repl                   # Flake outputs
xin --repl-core              # nixosConfigurations."$(hostname)"
xin --repl-home              # Current host's Home Manager config for $USER
xin --build                  # Build without activation
xin --switch                 # Build and activate
xin --boot                   # Build for the next boot
xin --test                   # Activate without changing the boot default
xin --repl-home --no-trace
xin --update hermes --dry-run
```

Choose one action per invocation. `--flake`, `--host`, and `--user` override the
checkout, host, and user. Pass backend arguments after `--`. Commands receive
arguments directly, without a shell evaluating their contents.

Tracing defaults on for Nix operations. `nh clean all` receives no trace flag
because it does not evaluate Nix expressions. The helper prefers `nh` for
rebuilds and cleanup when its executable is available. Without `nh`, rebuilds
use `nixos-rebuild`; cleanup uses `nix store gc`, which collects unreferenced
store paths without pruning generations. Checks, updates, and REPLs use Nix
directly so tracing and scoped entry points work consistently.

`nfu` remains an alias for `xin --update`. Updates change the lockfile without
building or publishing it. Review the changes, then run `nhs` or `xin --switch`
when ready to activate.

Validation:

```sh
rustc --edition 2024 --test Libraries/rust/src/xin.rs -o /tmp/xin-tests
/tmp/xin-tests
python3 -m unittest discover -s Tests/python -p test_xin.py
```

Hermes release metadata is saved in `Modules/nix/home/ai/agents/hermes/release.json`.
Full updates and targeted Hermes updates discover the latest stable Git tag and
refresh this file after Nix succeeds. Commit it with `flake.lock`. Evaluation
never fetches mutable release API responses. Direct `nix flake update` updates
source inputs only; use `xin --update hermes` to refresh the release label too.
