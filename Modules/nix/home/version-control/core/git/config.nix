{
  cfg,
  config,
  defined,
  entryAfter,
  lix,
  ...
}: let
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.transformation) filterAttrs;
  inherit (lix.strings.construction) concat;
  inherit (lix.filesystem.construction) concatPath;
  inherit (lix.strings.predicates) hasPrefix;
  inherit (lix.strings.transformation) escapeShellArg trimEnd;

  conf = {
    managed = escapeShellArg config.xdg.configFile."git/config".source;
    legacy = concatPath {
      root = config.home.homeDirectory;
      stem = ".gitconfig";
    };
  };
in {
  programs = {
    git = {
      inherit (cfg) enable lfs;
      settings =
        {inherit (cfg.settings) alias url core init push;}
        // optionalAttrs (defined ? name || defined ? email) {
          user = filterAttrs (_: value: value != null) {
            name = defined.name or null;
            email = defined.email or null;
          };
        };
      includes =
        cfg.includes
        ++ (
          map (identity: {
            condition = let
              dir =
                if
                  (identity.root == "~")
                  || (hasPrefix "~/" identity.root)
                  || (hasPrefix "/" identity.root)
                then identity.root
                else
                  concatPath {
                    root = "~";
                    stem = identity.root;
                  };
            in "gitdir:${trimEnd "/" dir}/";
            contents = recursiveUpdate identity.settings {
              user = filterAttrs (_: value: value != null) {
                inherit (identity) name email;
              };
            };
          })
          cfg.identities
        );
    };
  };

  #? Home Manager's activation framework provides DRY_RUN_CMD: it is empty
  #? normally and prefixes commands with a print-only command during dry runs.
  #? Home Manager owns ~/.config/git/config. Remove only legacy ~/.gitconfig
  #? keys that are now represented declaratively, preserving unrelated data.
  home = {
    activation.removeLegacyGitConfig = let
      inherit (lix.toolkit.binaries) gitCfgFile rmf;
      inherit (conf) managed legacy;
      keys = [
        "user.name"
        "user.email"
        "alias.project-summary"
        "push.autoSetupRemote"
        "credential.helper"
        "credential.https://github.com.helper"
        "credential.https://gist.github.com.helper"
      ];
    in
      entryAfter ["writeBoundary"] ''
        if [ -f "${legacy}" ]; then
          ${
          concat "\n" (
            map (key: let
              key' = escapeShellArg key;
            in ''
              if
                ${gitCfgFile} "${managed}" \
                  --no-includes --get-all ${key'} >/dev/null
              then
                $DRY_RUN_CMD \
                  ${gitCfgFile} "${legacy}" \
                  --unset-all ${key'} 2>/dev/null || true
              fi
            '')
            keys
          )
        }

          if remaining="$(${gitCfgFile} "${legacy}" --list)"; then
            if [ -z "$remaining" ]; then
              $DRY_RUN_CMD ${rmf} "${legacy}"
            fi
          else
            printf \
              'Preserving %s: unable to read Git configuration.\n' \
              "${legacy}" >&2
          fi
        fi
      '';
  };
}
