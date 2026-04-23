# OpenClaw Flake

A hardened, production-ready NixOS service flake for **OpenClaw**.

## Quickstart

```sh
# 1. Enter the developer shell (requires direnv + nix)
nix develop

# 2. Check everything builds and passes
nix flake check

# 3. Format all source files
fmt

# 4. Build the openclaw package
build
```

## nixpkgs Pinning Policy

> **Warning (verbatim from numtide):**
> "This flake is only built and tested against its pinned nixpkgs-unstable
> input. If you set `openclaw.inputs.nixpkgs.follows = 'nixpkgs'`, your nixpkgs
> must also track nixpkgs-unstable and be reasonably current — using a stable
> release branch (e.g. nixos-25.05) will break eventually. Omitting follows
> costs you a second nixpkgs evaluation but guarantees you get the combination
> we ship in CI — and lets you pull pre-built binaries from our binary cache
> instead of rebuilding everything against your nixpkgs."

This flake pins `nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"` unconditionally.

## Module Options

All options live under `services.openclaw.*`.

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `enable` | bool | `false` | Enable the openclaw service |
| `package` | package | `self.packages.<system>.openclaw` | The openclaw derivation to use |
| `port` | port (int) | `8080` | TCP port openclaw listens on |
| `host` | string | `"127.0.0.1"` | Bind address |
| `dataDir` | path | `"/var/lib/openclaw"` | Persistent state directory |
| `logLevel` | enum | `"info"` | Log verbosity: debug/info/warn/error |
| `openFirewall` | bool | `false` | Open the firewall for `port` |
| `tls.enable` | bool | `false` | Enable TLS on the listener |
| `tls.certFile` | path or null | `null` | Path to TLS certificate |
| `tls.keyFile` | path or null | `null` | Path to TLS private key |
| `extraConfig` | attrs | `{}` | Freeform extra configuration passed as JSON |
| `allowedIPs` | list of string | `[]` | IP ranges allowed through systemd IPAddressAllow |

## Secrets Bootstrap (age + sops)

```sh
# 1. Generate your age key
age-keygen -o ~/.config/sops/age/keys.txt

# 2. Copy the public key printed above into .sops.yaml
#    (a template is at secrets/.sops.yaml.example)

# 3. Create and encrypt your secrets
cp secrets/secrets.yaml.example secrets/secrets.yaml
# Edit secrets/secrets.yaml with real values
sops --encrypt --in-place secrets/secrets.yaml

# 4. Set the key file path in .envrc.local (never committed)
echo 'export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt' >> .envrc.local
direnv allow
```

## Using as a NixOS Module

```nix
# In your NixOS configuration flake:
{
  inputs.openclaw.url = "github:your-org/openclaw-flake";

  outputs = { self, nixpkgs, openclaw, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        openclaw.nixosModules.openclaw
        {
          services.openclaw = {
            enable = true;
            port   = 8080;
            tls.enable = true;
            tls.certFile = config.sops.secrets."openclaw/cert".path;
            tls.keyFile  = config.sops.secrets."openclaw/key".path;
            openFirewall = true;
          };
        }
      ];
    };
  };
}
```

## Developer Commands

| Command | Action |
| --- | --- |
| `fmt` | Run treefmt on all files |
| `check` | `nix flake check` |
| `build` | `nix build .#openclaw` |
| `run` | `nix run .#openclaw` |
| `test` | Build the NixOS VM test |
| `secrets-edit` | `sops secrets/secrets.yaml` |
| `gh` | GitHub CLI |
| `ghpr` | `gh pr create --fill` |
| `ghci` | `gh issue create` |
| `update` | `nix flake update` |

## Binary Cache

Add to `/etc/nix/nix.conf` (or `~/.config/nix/nix.conf`):

```nix
extra-substituters = https://cache.numtide.com
extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=
```
