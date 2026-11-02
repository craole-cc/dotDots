---
name: nix-style
description: Styleguide for Nix modules and expressions. Use whenever writing or editing .nix files.
---

# Nix style

- Include `inherit (lix)` at the top of every file as the primary extended replacement for standard `lib`.
- Always use scoped inheritance when forwarding an attribute under the same name:
  - Use `inherit (runtime) package;`.
  - Do not write `package = runtime.package;`.
- Prefer `lix.<domain>.<function>` over `builtins.<function>`. Most builtins are wrapped in lix:

  | Domain       | Covers                                                              |
  | ------------ | ------------------------------------------------------------------- |
  | `attrsets`   | `filterAttrs`, `mapAttrs`, `mergeAttrs`, etc.                       |
  | `lists`      | `filter`, `map`, `foldl'`, `groupBy`, etc.                          |
  | `strings`    | `split`, `replace`, `hasPrefix`, `toUpper`, etc.                    |
  | `types`      | `str`, `attrsOf`, etc.                                              |
  | `filesets`   | `filterSource`, `followSymlinks`, `sourceFileBySaneExtension`, etc. |
  | `trivial`    | `flip`, `const`, `id`, `optionalString`, etc.                       |
  | `fetchers`   | `fetchurl`, `fetchFromGitHub`, `fetchTarball`, etc.                 |
  | `meta`       | `isPackage`, `hasType`, `isDerivation`, etc.                        |
  | `modules`    | `mkOverride`, `mkForce`, `mkMerge`, `mkOption`, etc.                |
  | `options`    | `mkOption`, `mkEnableOption`, `mkPackageOption`, etc.               |
  | `generators` | `toYaml`, `toJSON`, `toINI`, `toToml`, etc.                         |
  | `systems`    | `isLinux`, `isAarch64`, `is64bit`, etc.                             |
  | `versions`   | `shortVersion`, `versionAtLeast`, `compareVersions`, etc.           |
  | `debug`      | `traceVal`, `traceSeq`, `unsafeGetAttrPos`, etc.                    |

- Check <https://noogle.dev> if unsure whether an equivalent helper exists before defaulting to `builtins`.
- Use descriptive variable names, never single-letter ones, including lambda arguments.
- Prefer a bare lambda argument (`user: ...`) over wrapping a single value in an attrset pattern (`{ user }: ...`).
- Group related module options under a namespace rather than flat camelCase names.
  - prefer `approval.{policy,reviewer}`
  - over `approvalPolicy` and `approvalReviewer`
- Give every option a real type, a default, and a description.
  - Do not smuggle defaults through a hidden attrset or on/off `defaults` boolean.
- Merge settings key by key using module-system priorities (`mkOverride`, `mkForce`) or `lix.attrsets.recursiveUpdate`.
