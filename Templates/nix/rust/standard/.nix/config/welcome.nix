# nix/welcome.nix
# Returns a shell script derivation that prints the welcome banner.
{ pkgs, tools }:
let
  inherit (pkgs) writeShellScript;
  inherit (pkgs.lib.strings) concatStringsSep;
  inherit (tools) magenta grey rustv;

  mkSection = title: content: ''
    ${magenta} " $ ${title}"
    ${grey} "${concatStringsSep "\n" (map (line: "  ${line}") content)}"
    echo ""
  '';

  mkHeader = title: subtitle: ''
    ${magenta} \
      --border-foreground 212 --border double \
      --align center --width 60 --margin "1 2" --padding "1 2" \
      "${title}" "${subtitle}"
  '';
in
writeShellScript "banner.sh" ''
  ${mkHeader "🦀 Rust Development Environment" "Toolchain: $(${rustv})"}

  ${mkSection "Auto-Deployed Templates" [
    "Templates are automatically deployed on shell entry"
    "Run deploy-templates to manually trigger deployment"
  ]}

  ${mkSection "Quick Start" [
    "cargo init <name>    # Create new project"
    "cargo new <name>     # Create with git"
    "edit                 # Open project in RustRover"
  ]}

  ${mkSection "Cargo Aliases" [
    "cargo b/br           # build / build --release"
    "cargo c/cl           # check / clippy"
    "cargo t/r/rr         # test / run / run --release"
    "cargo w/wr           # watch check / watch run"
  ]}

  ${mkSection "Watch Commands" [
    "bacon                # Watch mode (default)"
    "watch-run            # cargo watch run"
    "watch-test           # cargo watch nextest"
    "watch-lint           # cargo watch clippy"
  ]}

  ${mkSection "Mise Tasks" [
    "mise dev             # Watch mode with bacon"
    "mise test            # Run tests with nextest"
    "mise coverage        # Generate coverage report"
    "mise fmt             # Format all files"
    "mise audit           # Security audit"
  ]}

  ${mkSection "Shell Commands" [
    "test                 # cargo nextest run"
    "bench                # cargo bench"
    "coverage             # tarpaulin html report"
    "audit                # cargo audit"
    "clippy               # clippy -D warnings"
    "lint                 # treefmt + leptosfmt + clippy"
    "info                 # tokei + onefetch"
    "gt                   # open gitui"
  ]}

  ${mkSection "AI Tools" [
    "claw / claw-ask      # OpenClaw code search"
    "claw-idx             # Index codebase for OpenClaw"
    "cx                   # Codex CLI"
    "cx-full              # Codex full-auto mode"
    "ai / ai-arch         # Aider pair programmer"
  ]}

  ${mkSection "Environment" [
    "deploy-templates     # Manually deploy config templates"
    "init                 # Full project initialization"
    "reset                # Regenerate config files"
    "reload               # Reload the environment"
    "rustv / rustvv       # Print rust version"
    "update               # Update flake + cargo deps"
    "version              # Show all tool versions"
  ]}
''
