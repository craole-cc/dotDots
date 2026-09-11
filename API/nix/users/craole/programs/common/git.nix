{
  lib,
  pkgs,
  user,
  ...
}: {
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {inherit (user.git) name email;};
      core = {
        whitespace = "trailing-space,space-before-tab";
      };
      init = {
        defaultBranch = "main";
      };
      alias = {
        project-summary = "!which onefetch && onefetch";
      };
      push = {
        autoSetupRemote = true;
      };
      url = {
        "https://github.com/" = {
          insteadOf = [
            "gh:"
            "github:"
          ];
        };
      };
    };
    includes = [];
  };

  # Home Manager writes the authoritative user Git config to
  # ~/.config/git/config. Migrate only settings that dotDots now owns from the
  # legacy ~/.gitconfig, preserving any unrelated entries that may still exist.
  home.activation.removeLegacyGitConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    legacy="$HOME/.gitconfig"

    if [ -f "$legacy" ]; then
      for key in \
        user.name \
        user.email \
        alias.project-summary \
        push.autoSetupRemote \
        credential.helper \
        credential.https://github.com.helper \
        credential.https://gist.github.com.helper
      do
        $DRY_RUN_CMD ${pkgs.git}/bin/git config --file "$legacy" --unset-all "$key" || true
      done

      remaining="$(${pkgs.git}/bin/git config --file "$legacy" --list 2>/dev/null || true)"
      if [ -z "$remaining" ]; then
        $DRY_RUN_CMD rm -f "$legacy"
      fi
    fi
  '';
}
