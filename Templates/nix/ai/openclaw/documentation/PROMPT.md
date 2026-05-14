# OpenClaw Flake Initialization Prompt

You are an expert Nix/NixOS engineer. Your FIRST deliverable is this file
itself, saved as PROMPT.md at the repository root — a human-readable record of
the specification that produced the repo.

After writing PROMPT.md, generate every remaining file listed below, in full,
with no omissions, shortcuts, or "rest omitted" stubs. If your context window
forces a break, say "CONTINUING →" and resume immediately when prompted.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ UPSTREAM REFERENCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Study <https://github.com/numtide/llm-agents.nix> before writing anything. It is
your canonical structural reference. Key facts from that repo:

- The root contains ONLY: flake.nix, flake.lock, and dot-files (.gitignore,
  .envrc, etc.). No other .nix files live at root.
- blueprint auto-discovers packages/, checks/, devshell.nix, and lib/ relative
  to `src`. We override `src` to point at ./modules so every build artifact
  lives under ./modules, keeping the root clean.
- overlays/ and patches/ are separate from packages/ in llm-agents because
  overlays compose _across_ packages and need a different evaluation context. We
  replicate this separation — but we colocate them under ./modules so the root
  only ever holds flake.nix.
- devshell.nix is a standalone file consumed by blueprint — do NOT inline it
  into flake.nix. Keep it as ./modules/devshell.nix.
- treefmt.nix is likewise a standalone file at ./modules/treefmt.nix.
- checks/ is a real directory (./modules/checks/) discovered by blueprint. Do
  NOT merge checks into flake.nix.

  CRITICAL — nixpkgs pinning policy (verbatim from numtide): "This flake is only
  built and tested against its pinned nixpkgs-unstable input. If you set
  openclaw.inputs.nixpkgs.follows = 'nixpkgs', your nixpkgs must also track
  nixpkgs-unstable and be reasonably current — using a stable release branch
  (e.g. nixos-25.05) will break eventually. Omitting follows costs you a second
  nixpkgs evaluation but guarantees you get the combination we ship in CI — and
  lets you pull pre-built binaries from our binary cache instead of rebuilding
  everything against your nixpkgs."

  Therefore: this flake does NOT use `follows` for its own nixpkgs input. It
  pins `nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"` unconditionally.
  Consumers who want to override it may, but the README must include the above
  warning verbatim.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ REQUIRED REPOSITORY LAYOUT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Every file below must be generated in full.

ROOT (dot-files + flake only — nothing else) PROMPT.md # This specification
(first file output) flake.nix # Single flake; delegates everything to ./modules
flake.lock # Fully pinned; stub SHAs are acceptable — mark them .envrc # use
flake + .envrc.local pattern .gitignore # result, .direnv, secrets/_.yaml
(not_.yaml.enc) README.md # Quickstart, nixpkgs warning, module options table

MODULES (blueprint src = ./modules — all Nix lives here) modules/ devshell.nix #
numtide/devshell commands list (not inline in flake) treefmt.nix # treefmt-nix
config for all formatters

    packages/
      openclaw/
        default.nix                 # stdenv.mkDerivation — deterministic fetchFromGitHub
        wrapper.nix                 # makeWrapper: runtime PATH, config flags
      gh-tools/
        default.nix                 # pkgs.gh + wrapper reading GITHUB_TOKEN from env

      overlays/
        default.nix                 # Exposes openclaw + gh-tools into nixpkgs
        shared-nixpkgs.nix          # Cross-system overlay; follows llm-agents pattern

    checks/
      default.nix                   # Aggregates all checks for blueprint discovery
      openclaw-unit.nix             # nixosTest: boot VM, assert service health
      format.nix                    # treefmt --fail-on-change
      secrets-lint.nix              # grep Nix store path for secret patterns

    openclaw/
      default.nix                   # Re-exports all sub-modules
      service.nix                   # systemd unit + full hardening directives
      config.nix                    # All lib.mkOption declarations
      security.nix                  # AppArmor/seccomp, capability dropping
      tls.nix                       # ACME / self-signed, TLS 1.3 preferred
      networking.nix                # Firewall, nginx + caddy reverse-proxy snippets
      secrets.nix                   # sops-nix integration; .sops.yaml template

    lib/
      default.nix                   # mkOpenClawConfig, mkSecureService helpers
      options.nix                   # Shared NixOS option types

.github/ workflows/ ci.yml # nix flake check + treefmt + nixosTest
security-scan.yml # Trivy/grype + sops lint

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ FLAKE STRUCTURE (flake.nix)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The flake.nix must be MINIMAL — all logic delegates to blueprint. Model it
closely on <https://github.com/numtide/llm-agents.nix/blob/main/flake.nix>.

inputs: nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable" # NO follows — see
nixpkgs pinning policy above systems.url = "github:nix-systems/default"
blueprint = { url = "github:numtide/blueprint"; inputs.nixpkgs.follows =
"nixpkgs"; inputs.systems.follows = "systems"; } treefmt-nix = { url =
"github:numtide/treefmt-nix"; inputs.nixpkgs.follows = "nixpkgs"; } flake-parts
= { url = "github:hercules-ci/flake-parts"; inputs.nixpkgs-lib.follows =
"nixpkgs"; } devshell = { url = "github:numtide/devshell";
inputs.nixpkgs.follows = "nixpkgs"; inputs.systems.follows = "systems"; }
sops-nix = { url = "github:Mic92/sops-nix"; inputs.nixpkgs.follows = "nixpkgs";
} nixos-generators = { url = "github:nix-community/nixos-generators";
inputs.nixpkgs.follows = "nixpkgs"; }

nixConfig: extra-substituters = [ "https://cache.numtide.com" ]
extra-trusted-public-keys = [
"niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ]

outputs = inputs: let blueprintOutputs = inputs.blueprint { inherit inputs; src
= ./modules; # ← key: all discovery happens under ./modules
nixpkgs.config.allowUnfree = true; }; in blueprintOutputs // { overlays = {
default = import ./modules/packages/overlays { inherit (blueprintOutputs)
packages; }; shared-nixpkgs = import
./modules/packages/overlays/shared-nixpkgs.nix { inherit (blueprintOutputs)
mkPackagesFor; }; }; nixosModules = { openclaw = import ./modules/openclaw;
default = import ./modules/openclaw; }; };

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ OVERLAY DESIGN (modules/packages/overlays/)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Overlays live _inside_ packages/ because they are a composition of the packages
built in the sibling directories. They are not standalone — they reference
`openclaw` and `gh-tools` derivations from ../openclaw and ../gh-tools.

overlays/default.nix: Called with `{ packages }` (the blueprint packages
attrset). Returns a nixpkgs overlay:
`final: prev: { inherit (packages.x86_64-linux)
    openclaw gh-tools; }`.
Include a comment explaining why overlays live here rather than at root.

overlays/shared-nixpkgs.nix: Called with `{ mkPackagesFor }`. Returns an overlay
that evaluates packages for the host system on demand. Mirror the pattern in
llm-agents.nix overlays/shared-nixpkgs.nix exactly.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ SECURITY REQUIREMENTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Apply ALL of the following in modules/openclaw/security.nix and service.nix.

systemd hardening (service.nix): DynamicUser = true PrivateTmp = true
PrivateDevices = true ProtectSystem = "strict" ProtectHome = true
NoNewPrivileges = true RestrictSUIDSGID = true MemoryDenyWriteExecute = true
RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ] SystemCallFilter =
[ "@system-service" "~~@privileged" "~~@resources" ] CapabilityBoundingSet = []
LockPersonality = true RestrictRealtime = true ProtectKernelTunables = true
ProtectKernelModules = true ProtectControlGroups = true IPAddressDeny = "any" #
override per services.openclaw.allowedIPs

TLS (tls.nix): Minimum TLS 1.2, prefer 1.3 Ciphers: TLS_AES_256_GCM_SHA384,
TLS_CHACHA20_POLY1305_SHA256, ECDHE-ECDSA-AES256-GCM-SHA384,
ECDHE-RSA-AES256-GCM-SHA384 HSTS: max-age=31536000; includeSubDomains; preload
OCSP stapling enabled

Secrets (secrets.nix): All secrets via config.sops.secrets Provide a
secrets/secrets.yaml.example and .sops.yaml template No secret value ever in a
Nix store path Document age-keygen bootstrap in README.md

Network (networking.nix): Default-deny firewall Option
services.openclaw.openFirewall (bool, default false) nginx + caddy reverse proxy
snippets with headers: X-Frame-Options DENY X-Content-Type-Options nosniff
Referrer-Policy strict-origin-when-cross-origin Content-Security-Policy
"default-src 'self'" Permissions-Policy "geolocation=(), microphone=(),
camera=()"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ OPENCLAW MODULE OPTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

All defined in modules/openclaw/config.nix using lib.mkOption with type,
default, description, and example for every option. No `with lib;` — use
explicit lib. prefixes throughout.

services.openclaw.enable bool, default false services.openclaw.package package,
default pkgs.openclaw services.openclaw.port port, default 8080
services.openclaw.host str, default "127.0.0.1" services.openclaw.dataDir path,
default "/var/lib/openclaw" services.openclaw.logLevel enum ["debug" "info"
"warn" "error"], default "info" services.openclaw.openFirewall bool, default
false services.openclaw.tls.enable bool, default false
services.openclaw.tls.certFile nullOr path, default null
services.openclaw.tls.keyFile nullOr path, default null
services.openclaw.extraConfig attrs, default {} services.openclaw.allowedIPs
listOf str, default []

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ DEVELOPER SHELL (modules/devshell.nix)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Use numtide/devshell `commands` list pattern — NOT raw buildInputs.

Commands to expose: fmt → treefmt check → nix flake check build → nix build
.#openclaw run → nix run .#openclaw test → nix build
.#checks.x86_64-linux.openclaw-unit secrets-edit → sops secrets/secrets.yaml gh
→ github cli ghpr → gh pr create --fill ghci → gh issue create update → nix
flake update

Shell env vars (instruct operators to set values in .envrc.local, never commit):
OPENCLAW_LOG_LEVEL OPENCLAW_PORT SOPS_AGE_KEY_FILE GITHUB_TOKEN

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ FORMATTING (modules/treefmt.nix)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

nixfmt-rfc-style _.nix prettier_.md _.json_.yaml _.yml shfmt _.sh (indent: 2,
simplify: true) taplo _.toml deadnix --edit (remove unused bindings) statix
(lint anti-patterns) Exclude: [ "flake.lock" "_.age" "secrets/\*.yaml" ]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ CHECKS (modules/checks/)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

checks/openclaw-unit.nix — real lib.nixosTest:

- Boot minimal NixOS VM, import modules/openclaw
- Enable services.openclaw on port 8080
- Assert systemd unit reaches "active (running)"
- Assert curl -f <http://127.0.0.1:8080/health> → HTTP 200
- Assert process runs as non-root DynamicUser
- Assert /proc/<pid>/status shows CapPrm: 0000000000000000

checks/secrets-lint.nix — runCommand that greps the build output path for: BEGIN
PRIVATE KEY, BEGIN RSA PRIVATE KEY, AKIA[A-Z0-9]{16}, password\s*=\s*"[^"]+"
Fail if any match found.

checks/format.nix — treefmt --fail-on-change wrapped as a Nix check.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ OUTPUT CONTRACTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

packages.<system>.openclaw packages.<system>.gh-tools packages.<system>.default
→ openclaw apps.<system>.openclaw apps.<system>.default
devShells.<system>.default nixosModules.openclaw nixosModules.default
overlays.default overlays.shared-nixpkgs checks.<system>.openclaw-unit
checks.<system>.format checks.<system>.secrets-lint formatter.<system> → treefmt
as `nix fmt`

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ GITHUB ACTIONS (.github/workflows/)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ci.yml:

- uses: cachix/install-nix-action@v26 with: nix_path:
  nixpkgs=channel:nixos-unstable
- uses: DeterminateSystems/magic-nix-cache-action@main
- Steps: checkout → install nix → nix flake check → nix fmt check → nixosTest
- gh CLI authenticated via ${{ secrets.GITHUB_TOKEN }}

security-scan.yml:

- Trivy filesystem scan on the built derivation output
- grype scan
- sops secret lint (grep for unencrypted patterns in tracked files)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ STYLE RULES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. alejandra style throughout: 2-space indent, trailing commas, RFC formatting.
2. Every module file opens with:

   # Module: <name>

   # Purpose: <one sentence>

   # Maintainer: openclaw-flake contributors

3. lib.mkOption with type + default + description + example on every option.
4. lib.mkIf config.services.openclaw.enable guards in service/security modules.
5. lib.types.package for package options, never raw pkgs references.
6. No `with lib;` anywhere — explicit lib. prefixes only.
7. devshell uses `commands` list, not buildInputs.
8. flake.nix stays under 60 lines — all logic in ./modules.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ DELIVERABLE FORMAT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Output each file as:

### path/to/file.ext

```nix (or yaml / sh / md as appropriate)
<complete file contents>
```

Order: PROMPT.md → flake.nix → flake.lock → .envrc → .gitignore → README.md →
modules/devshell.nix → modules/treefmt.nix → modules/packages/... →
modules/checks/... → modules/openclaw/... → modules/lib/... →
.github/workflows/...

After all files, output:

## Bootstrap Instructions

Numbered steps from fresh clone through live deployment: 1. nix develop 2.
age-keygen, sops setup, .sops.yaml config 3. Populate secrets/secrets.yaml +
sops --encrypt 4. nix flake check 5. Add
`imports = [ openclaw-flake.nixosModules.openclaw ]` to NixOS config 6. Set
services.openclaw.enable = true 7. nixos-rebuild switch --flake .#hostname 8.
Verify with systemctl status openclaw and curl health endpoint
