{lib, ...}: let
  inherit (lib.strings) concatStrings;
in {
  settings = {
    command_timeout = 1111;
    scan_timeout = 1000;
    format = concatStrings [
      ""
      "$character"
      ""
    ];
    right_format = concatStrings [
      ""
      "$all"
      ""
    ];
    continuation_prompt = "[▶▶ ](dimmed white)";
    add_newline = true;

    # cmd_duration = {
    #   # format = "[◄ $duration ](italic white)"
    #   min_time = 1000;
    #   show_notifications = true;
    # };

    # file = {
    #   symbol = " ";
    # };

    character = {
      format = "$symbol ";
      success_symbol = "[  ](bold italic bright-yellow)";
      error_symbol = "[  ](bold red)";
      vimcmd_symbol = "[](italic dimmed green)";
      vimcmd_replace_one_symbol = "◌";
      vimcmd_replace_symbol = "□";
      vimcmd_visual_symbol = "▼";
    };

    directory = {
      format = "[$path]($style)[$read_only]($read_only_style) ";
      truncate_to_repo = false;
      truncation_length = 4;
      truncation_symbol = "…/";

      substitutions = {
        style = "bold green";
        home_symbol = " ";
        read_only = "  ";
        "~/.dots" = " ";
        "~/.config" = " ";
        "Documents" = " ";
        "archives" = " ";
        "Downloads" = " ";
        "Music" = " ";
        "Videos" = " ";
        "Pictures" = "  ";
        "global" = " ";
      };
    };

    time = {
      # disabled = true;
      format = "󱑏 [ $time ]($style)";
      time_format = "%H:%M";
      time_range = "22:00:00-07:00:00";
      utc_time_offset = "-5";
    };

    # shell = {
    #   disabled = true;
    # };

    # sudo = {
    #   allow_windows = true;
    #   format = "[$symbol]($style)";
    #   style = "bold italic bright-purple";
    #   symbol = " ";
    #   disabled = true;
    #   # symbol = "[ ](bold red)";
    #   # symbol = "[ ](bold red)";
    #   # symbol = "[󱨚  ](bold red)";
    #   # disabled = true;
    # };

    # git_branch = {
    #   format = " [$branch(:$remote_branch)]($style)";
    #   symbol = "[△](bold italic bright-blue)";
    #   style = "italic bright-blue";
    #   truncation_symbol = "⋯";
    #   truncation_length = 11;
    #   ignore_branches = ["main", "master"];
    #   only_attached = true;
    # };

    # git_metrics={
    #   format = "([▴$added]($added_style))([▿$deleted]($deleted_style)) ";
    #   added_style = "italic dimmed green";
    #   deleted_style = "italic dimmed red";
    #   ignore_submodules = false;
    #   disabled = true;
    # };

    # git_status={
    #   style = "bold bright-blue";
    #   format = "([$ahead_behind$staged$modified$untracked$renamed$deleted$conflicted$stashed  ]($style))";
    #   ahead = "[ ${count}󰬥](italic green)";
    #   behind = "[ ${count}󰬤](italic red)";
    #   staged = "[ $count](bold italic bright-cyan)";
    #   modified = "[ $count](bold italic yellow)";
    #   untracked = "[ $count](bold italic cyan)";
    #   deleted = "[ $count](bold italic red)";
    #   conflicted = "[ $count ](italic bright-magenta)";
    #   diverged = "[ $count](bold italic bright-magenta)";
    #   renamed = "[ $count](bold italic bright-blue)";
    #   stashed = "[ $count](bold italic cyan)";
    #   up_to_date = "";
    #   # disabled = true;
    #   };

    # battery = {
    #   format = "[ $percentage $symbol]($style)";
    #   full_symbol = " ";
    #   charging_symbol = " ";
    #   discharging_symbol = " ";
    #   unknown_symbol = " ";
    #   empty_symbol = " ";
    #   disabled = true;

    #   display = [
    #     {
    #       threshold = 20;
    #       style = "italic bold red";
    #     }
    #     {
    #       threshold = 60;
    #       style = "italic dimmed bright-purple";
    #     }
    #     {
    #       threshold = 70;
    #       style = "italic dimmed yellow";
    #     }
    #   ];
    # };

    # nix_shell = {
    #   style = "bold italic dimmed blue";
    #   symbol = " ";
    #   format = "[$symbol $state]($style) [$name ](italic dimmed white)";
    #   impure_msg = "[⌽](bold dimmed red)";
    #   pure_msg = "[⌾](bold dimmed green)";
    #   unknown_msg = "[◌](bold dimmed yellow)";
    # };
  };
}
