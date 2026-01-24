{
  settings = {
    format = ''
      $directory\
      $git_branch\
      $git_status\
      $git_metrics\
      $line_break\
      $character'';

    git_branch = {
      symbol = " ";
      format = "[$symbol$branch]($style) ";
      style = "bold purple";
    };

    git_status = {
      format = "([$all_status$ahead_behind]($style) )";
      style = "bold red";
      ahead = "⇡$count ";
      behind = "⇣$count ";
      diverged = "⇕⇡$ahead_count⇣$behind_count ";
      untracked = "?$count ";
      stashed = "$count ";
      modified = "!$count ";
      staged = "+$count ";
      renamed = "»$count ";
      deleted = "✘$count ";
      conflicted = "=$count ";
    };

    git_metrics = {
      disabled = false;
      format = "([+$added]($added_style) )([-$deleted]($deleted_style) )";
      added_style = "bold green";
      deleted_style = "bold red";
    };

    character = {
      success_symbol = "[❯](bold green)";
      error_symbol = "[❯](bold red)";
    };

    directory = {
      truncation_length = 3;
      format = "[$path]($style) ";
      style = "bold cyan";
    };
  };
}
