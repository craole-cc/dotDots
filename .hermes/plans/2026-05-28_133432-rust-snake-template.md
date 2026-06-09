# Rust Snake Template Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan
> task-by-task.

**Goal:** Add a dedicated Rust + Nix flake template that boots into a playable
Snake game with a clean devshell, good file separation, and a name that fits the
repository’s existing template layout.

**Architecture:** Create a new standalone template at
`Templates/nix/rust/snake/` and expose it through `Templates/nix/default.nix`.
Base the devshell approach on the existing `Templates/nix/rust/comprehensive/`
pattern, but trim it to game-focused Rust development. Implement the game with
`macroquad` so the template stays simple, cross-platform, and easier to package
in a Nix devshell than a heavier engine stack.

**Tech Stack:** Nix flakes, Rust, `macroquad`, cargo, rustfmt, clippy, treefmt.

---

## Recommended naming

- **Folder path:** `Templates/nix/rust/snake`
- **Flake template attr name:** `rust-snake`
- **Description:** `Rust Snake game starter with Nix devshell`

Why this name:

- It matches the repo’s short, direct template naming style.
- It avoids overloading the existing `rust` default template.
- It leaves room for future sibling templates like `rust-bevy`, `rust-web`, or
  `rust-tui`.

---

## Current context / assumptions

- The repository already exports templates from `Templates/nix/default.nix`.
- Existing Rust template patterns live under:
  - `Templates/nix/rust/comprehensive/`
  - `Templates/nix/rust/workspace/`
- Repo-level template exposure currently includes `rust` and `rustspace`.
- The user wants **plan first**, so no implementation changes should happen yet.
- Preferred style should stay modular and folder-based, with clear separation
  instead of a single-file demo.

---

## Proposed approach

1. Add a new self-contained flake template under `Templates/nix/rust/snake/`.
2. Reuse the repository’s Rust/Nix conventions where helpful, but do **not**
   wedge Snake-specific code into the generic comprehensive template.
3. Keep the game code separated into focused Rust modules:
   - config/constants
   - direction/input
   - board/position
   - snake state
   - food spawning
   - game state/update loop
   - rendering
4. Use `macroquad` for a lightweight 2D windowed game template.
5. Include a minimal but real test surface for game logic that does not require
   opening a graphics window.
6. Wire the new template into the root `templates` export without disturbing the
   current `default = templates.rust` behavior unless explicitly desired later.

---

## Files likely to change

### Repository wiring

- Modify: `Templates/nix/default.nix`

### New template root

- Create: `Templates/nix/rust/snake/flake.nix`
- Create: `Templates/nix/rust/snake/default.nix`
- Create: `Templates/nix/rust/snake/.envrc`
- Create: `Templates/nix/rust/snake/.gitignore`
- Create: `Templates/nix/rust/snake/README.md`
- Create: `Templates/nix/rust/snake/Cargo.toml`
- Create: `Templates/nix/rust/snake/rust-toolchain.toml`
- Create: `Templates/nix/rust/snake/rustfmt.toml`
- Create: `Templates/nix/rust/snake/treefmt.toml`

### Game source layout

- Create: `Templates/nix/rust/snake/src/main.rs`
- Create: `Templates/nix/rust/snake/src/lib.rs`
- Create: `Templates/nix/rust/snake/src/game/mod.rs`
- Create: `Templates/nix/rust/snake/src/game/config.rs`
- Create: `Templates/nix/rust/snake/src/game/types.rs`
- Create: `Templates/nix/rust/snake/src/game/direction.rs`
- Create: `Templates/nix/rust/snake/src/game/snake.rs`
- Create: `Templates/nix/rust/snake/src/game/food.rs`
- Create: `Templates/nix/rust/snake/src/game/state.rs`
- Create: `Templates/nix/rust/snake/src/game/update.rs`
- Create: `Templates/nix/rust/snake/src/game/render.rs`
- Create: `Templates/nix/rust/snake/src/game/input.rs`

### Tests / assets

- Create: `Templates/nix/rust/snake/tests/game_logic.rs`
- Create: `Templates/nix/rust/snake/assets/.gitkeep`

Optional only if needed after implementation review:

- Create: `Templates/nix/rust/snake/.vscode/settings.json`
- Create: `Templates/nix/rust/snake/.vscode/launch.json`

---

## Step-by-step plan

### Task 1: Confirm the template export shape and naming slot

**Objective:** Verify how the repo exposes templates so the new template is
added in the smallest, cleanest way.

**Files:**

- Modify: `Templates/nix/default.nix`

**Steps:**

1. Inspect `Templates/nix/default.nix` and confirm the attr naming convention.
2. Add a new export entry named `rust-snake` pointing at `./rust/snake`.
3. Keep `default = templates.rust` unchanged unless the user later asks to make
   Snake the default Rust starter.
4. Ensure the description clearly says it is a Snake starter, not a general Rust
   shell.

**Verification:**

- `nix flake show` from repo root should list the new template attr.
- Existing template attrs should still resolve.

---

### Task 2: Create the new template folder with minimal flake entrypoints

**Objective:** Establish the new template as an isolated, reusable starter.

**Files:**

- Create: `Templates/nix/rust/snake/flake.nix`
- Create: `Templates/nix/rust/snake/default.nix`
- Create: `Templates/nix/rust/snake/.envrc`
- Create: `Templates/nix/rust/snake/.gitignore`
- Create: `Templates/nix/rust/snake/README.md`

**Steps:**

1. Copy only the useful shell/dev conventions from `rust/comprehensive`, not the
   entire internal framework.
2. Keep this template readable as a starter project, with straightforward Nix
   and Rust files.
3. Document how to enter the shell, run the game, and run tests.
4. Ignore `target/`, `.direnv/`, and generated artifacts.

**Verification:**

- `nix develop ./Templates/nix/rust/snake` should enter a usable shell.
- `cargo --version` and `rustc --version` should work inside the shell.

---

### Task 3: Define the game-focused devshell

**Objective:** Build a devshell that is comprehensive enough for Rust game work
without carrying unrelated bloat.

**Files:**

- Create: `Templates/nix/rust/snake/flake.nix`
- Create: `Templates/nix/rust/snake/default.nix`
- Create: `Templates/nix/rust/snake/rust-toolchain.toml`
- Create: `Templates/nix/rust/snake/treefmt.toml`
- Create: `Templates/nix/rust/snake/rustfmt.toml`

**Steps:**

1. Pin `nixpkgs` and `rust-overlay` similarly to the workspace template unless
   repo conventions suggest a better local helper.
2. Include a Rust toolchain with:
   - `rustc`
   - `cargo`
   - `clippy`
   - `rustfmt`
   - `rust-src`
   - `rust-analyzer`
3. Add common Rust productivity tools only if they are directly useful for this
   starter, such as:
   - `cargo-watch`
   - `bacon`
4. Add any runtime/system packages needed by `macroquad` on Linux.
5. Expose a shell hook or README guidance for common commands:
   - `cargo run`
   - `cargo test`
   - `cargo clippy --all-targets --all-features -- -D warnings`
   - `cargo fmt --all`

**Verification:**

- `nix develop ./Templates/nix/rust/snake -c cargo fmt --all --check`
- `nix develop ./Templates/nix/rust/snake -c cargo clippy --all-targets --all-features -- -D warnings`

**Risk / tradeoff:**

- Reusing too much of `rust/comprehensive` may make the starter harder to
  understand.
- Reusing too little may drift from repo conventions. Favor readability first.

---

### Task 4: Scaffold the Cargo project for clean game/app separation

**Objective:** Set up a project layout that keeps core game logic testable and
rendering-specific code isolated.

**Files:**

- Create: `Templates/nix/rust/snake/Cargo.toml`
- Create: `Templates/nix/rust/snake/src/main.rs`
- Create: `Templates/nix/rust/snake/src/lib.rs`
- Create: `Templates/nix/rust/snake/src/game/mod.rs`

**Steps:**

1. Make `src/main.rs` the thin executable entrypoint.
2. Put reusable game logic in `src/lib.rs` and `src/game/*`.
3. Add dependencies for:
   - `macroquad`
   - a small RNG crate if needed (`rand`) unless `macroquad::rand` is enough
4. Keep rendering and update logic separate so tests can exercise pure state
   transitions.

**Verification:**

- `cargo check`
- `cargo test` should compile the library and test targets even before full
  rendering polish.

---

### Task 5: Implement the core domain types first

**Objective:** Establish deterministic game state primitives before writing the
full loop.

**Files:**

- Create: `Templates/nix/rust/snake/src/game/config.rs`
- Create: `Templates/nix/rust/snake/src/game/types.rs`
- Create: `Templates/nix/rust/snake/src/game/direction.rs`
- Create: `Templates/nix/rust/snake/src/game/snake.rs`

**Steps:**

1. Define board and timing constants in `config.rs`.
2. Define reusable grid coordinates and related helpers in `types.rs`.
3. Define movement directions and the “no instant reverse” rule in
   `direction.rs`.
4. Define snake body state and movement helpers in `snake.rs`.

**Tests:**

- Direction reversal is rejected.
- Snake head advances correctly.
- Snake growth updates length correctly.

**Verification:**

- `cargo test tests/game_logic.rs -- --nocapture` or targeted test names.

---

### Task 6: Implement food spawning and game state transitions

**Objective:** Make the game actually playable as a state machine before
worrying about rendering polish.

**Files:**

- Create: `Templates/nix/rust/snake/src/game/food.rs`
- Create: `Templates/nix/rust/snake/src/game/state.rs`
- Create: `Templates/nix/rust/snake/src/game/update.rs`

**Steps:**

1. Add food placement that avoids current snake cells.
2. Track score, running state, and game-over state.
3. Implement a tick/update function that:
   - reads the next queued direction
   - advances the snake
   - checks wall collision
   - checks self collision
   - handles food consumption and respawn
4. Keep update logic pure where possible.

**Tests:**

- Food never spawns on the snake.
- Eating food grows the snake and increments score.
- Wall collision triggers game over.
- Self collision triggers game over.

**Verification:**

- `cargo test`

---

### Task 7: Implement input and rendering as thin outer layers

**Objective:** Connect pure game state to windowed gameplay without tangling
core logic.

**Files:**

- Create: `Templates/nix/rust/snake/src/game/input.rs`
- Create: `Templates/nix/rust/snake/src/game/render.rs`
- Modify: `Templates/nix/rust/snake/src/main.rs`

**Steps:**

1. Read keyboard input in `input.rs` and convert it into direction changes and
   restart commands.
2. Draw board, snake, food, score, and game-over overlay in `render.rs`.
3. Keep `main.rs` limited to the `macroquad` loop and orchestration.
4. Make the game start immediately and allow restart after loss.

**Verification:**

- `cargo run`
- Manual play test:
  - movement works
  - opposite direction reversal is blocked
  - eating increases score
  - collision ends game
  - restart works

---

### Task 8: Add template polish and onboarding docs

**Objective:** Make the template usable by someone cloning it cold.

**Files:**

- Modify: `Templates/nix/rust/snake/README.md`
- Create: `Templates/nix/rust/snake/assets/.gitkeep`

**Steps:**

1. Document what the template is for.
2. Document how to instantiate/use it through `nix flake init -t` or the repo’s
   chosen template workflow.
3. Document the project structure and why logic lives in `src/game/*`.
4. Document the most useful commands.
5. Mention where to extend the project next:
   - pause state
   - wrap-around mode
   - high scores
   - audio
   - textures

**Verification:**

- README instructions should work from a clean checkout.

---

### Task 9: Validate the template end-to-end

**Objective:** Ensure the template works as an actual exported starter, not just
as a directory of files.

**Files:**

- Modify only as needed based on failures discovered above.

**Steps:**

1. Run repo-level visibility checks for template export.
2. Instantiate or enter the template directly.
3. Run formatting, linting, tests, and a manual run.
4. Confirm no unrelated templates broke.

**Verification:**

- `nix flake show`
- `nix develop ./Templates/nix/rust/snake -c cargo check`
- `nix develop ./Templates/nix/rust/snake -c cargo test`
- `nix develop ./Templates/nix/rust/snake -c cargo fmt --all --check`
- `nix develop ./Templates/nix/rust/snake -c cargo clippy --all-targets --all-features -- -D warnings`
- Optional broader repo check if affordable: `nix flake check`

---

## Testing / validation strategy

### Automated

- Template attr appears in `nix flake show`
- New template shell evaluates successfully
- `cargo check`
- `cargo test`
- `cargo fmt --all --check`
- `cargo clippy --all-targets --all-features -- -D warnings`

### Manual

- Launch the game window with `cargo run`
- Confirm keyboard input responsiveness
- Confirm snake growth and score updates
- Confirm game-over and restart flow

---

## Risks, tradeoffs, and open questions

### Risks

- `macroquad` runtime dependencies may need a small amount of Linux-specific Nix
  packaging.
- If the template leans too hard on the existing comprehensive infra, it may
  stop feeling like a clear starter template.
- If everything is placed in `main.rs`, the template will be easy to read but
  bad as an example of separation. Avoid that.

### Tradeoffs

- **Macroquad vs Bevy:** `macroquad` is simpler and better for a Snake starter;
  `bevy` is more scalable but heavier and noisier for a first template.
- **Standalone flake vs reusing comprehensive internals:** standalone is easier
  to understand; reuse improves consistency. Prefer a standalone template that
  borrows conventions, not implementation complexity.

### Open questions for implementation phase

- Should the template also expose a `justfile` or stay cargo-first?
- Should the devshell include audio/image tooling up front, or keep it minimal
  and game-only?
- Should the root `templates.default` remain the existing `rust` template, or
  should `rust-snake` become an explicit game starter only?

---

## Suggested implementation order for execution

1. Repo template export
2. New template skeleton
3. Devshell/toolchain
4. Cargo scaffold
5. Pure game logic + tests
6. Rendering/input
7. Docs and validation

---

## Acceptance criteria

The work is done when:

- The repo exposes a new `rust-snake` template.
- The template lives in its own dedicated folder under
  `Templates/nix/rust/snake/`.
- Entering the devshell works on the template.
- `cargo run` starts a playable Snake game.
- The code is cleanly separated into game modules rather than one large file.
- Core game logic has tests.
- README usage instructions are accurate.
