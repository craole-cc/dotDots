{lib, ...}: {
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      aws.disabled = true;
      gcloud.disabled = true;
      line_break.disabled = true;
      # format = lib.concatStrings [
      #   "$username"
      #   "$hostname"
      #   "$directory"
      #   "$git_branch"
      #   "$git_commit"
      #   "$git_state"
      #   "$git_status"
      #   "$package"
      #   "$haskell"
      #   "$python"
      #   "$rust"
      #   "$nix_shell"
      #   "$line_break"
      #   "$jobs"
      #   "$character"
      # ];
      shell = {
        disabled = false;
        format = "$indicator";
        fish_indicator = "";
        bash_indicator = "[BASH](bright-white) ";
        zsh_indicator = "[ZSH](bright-white) ";
      };
      username = {
        style_user = "bright-white bold";
        style_root = "bright-red bold";
      };
    };
  };
}
