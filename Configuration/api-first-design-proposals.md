# API-First Design Proposals

This document records the three deliberately unimplemented design points. Their implementation is held until the owner approves the proposals.

## Development capability precedence

The normalized value will be `host.capabilities.development`, and Modules will consume only that normalized value through a visible `${top}` option.

Proposed resolution, from strongest to weakest:

1. An explicit raw host value `host.capabilities.development = false` is an absolute disable.
2. An explicit raw host value `host.capabilities.development = true` is an absolute enable.
3. An explicit host lockdown posture (`host.hardened = true` or `host.posture = "locked-down"`) disables inferred development capability. This is an opt-out from the permissive server baseline.
4. A host-level development declaration (`host.functionalities` contains `"development"`, or an equivalent explicit host capability) enables it.
5. Any enabled interactive user whose capabilities contain `"development"` enables it.
6. Otherwise the default for a non-locked-down host is `true`, because capable general-purpose servers should support development by default.

The raw schema must preserve the difference between absent and explicit `false`; therefore the explicit host field should be `nullOr bool` rather than a plain boolean. The final module option remains overrideable: `${top}.programs.nix-ld.enable` wins over the normalized API default.

## Live system-wide theme polarity

Darkman remains the proposed day/night trigger and manual override entrypoint. It is a trigger/orchestrator, not the per-application implementation. The API policy should normalize into a visible option tree resembling:

- `${top}.interface.theme.enable`
- `${top}.interface.theme.autoSwitch`
- `${top}.interface.theme.day`
- `${top}.interface.theme.night`
- `${top}.interface.theme.manualOverride`
- `${top}.interface.theme.current`
- `${top}.interface.theme.dispatcher.enable`
- `${top}.interface.theme.dispatcher.statePath`

`current` is runtime state and must not be treated as a declarative permanent value. The dispatcher owns a small state file and emits one polarity event. Darkman hooks update that state; a manual command writes the override and emits the same event.

The proposed propagation mechanism is a user-level `theme-dispatcher` service plus a common event contract:

1. Darkman day/night hooks and the manual toggle command call the dispatcher.
2. The dispatcher writes `dark` or `light` to the configured state path and emits a user-session signal.
3. Each themed component declares a visible reaction option and a reload mechanism.
4. Reactions use the least invasive supported mechanism:
   - foot: regenerate/include the active palette and send `SIGUSR1` or use `footclient` reconfigure;
   - Ghostty: update the selected config and invoke its supported reload-config action/IPC;
   - GTK: update the portal/GSettings color scheme and theme settings;
   - Qt/Kvantum: update the selected theme/config and invoke the available live reload path, otherwise restart only the affected process;
   - Hyprlock: regenerate before the next lock invocation (it is not a persistent process);
   - Waybar: update CSS/config and send its reload signal;
   - Caelestia/Noctalia/Quickshell: use their IPC/reload interface where supported;
   - VS Code: use the supported settings/theme command or update managed settings through the running instance;
   - Helix: use its runtime theme command if externally triggerable, otherwise document restart/next-session behavior.

Before implementation, the exact support and command for each component must be verified against the repository's current module and the installed program version. Components without a true live reload path must be explicitly marked `restartRequired = true`; they must not be described as live-switching merely because their files are declarative.

## Filesystem presence and zero-filesystem hosts

The schema should add `host.hardware.hasFilesystems`, derived from `host.devices.file` rather than from a hardcoded module default.

Proposed repository policy: a real `class = "nixos"` host must declare at least `/`. A zero-filesystem host is more plausibly a template, test, container, or ephemeral evaluation target than a bootable machine in this repository. Therefore:

- `${top}.hardware.filesystems.enable` defaults to `host.hardware.hasFilesystems`;
- the schema exposes `host.storage.filesystemsRequired`, defaulting to `true` for real NixOS hosts;
- the module asserts that at least one filesystem exists when `filesystemsRequired` is true;
- a template/container/ephemeral host may explicitly set `filesystemsRequired = false`, in which case the module remains valid but disabled by default.

This avoids silently accepting a malformed real host while preserving an explicit escape hatch for non-bootable test systems.
