{
  programs.zed-editor = {

    #> Themes
    theme = {
      mode = "system";
      light = "Catppuccin Latte";
      dark = "Catppuccin Frappé";
    };

    icon_theme = {
      mode = "system";
      light = "Catppuccin Latte";
      dark = "Catppuccin Frappé";
    };

    #> Editor Appearance
    buffer_font_size = 20;
    buffer_font_weight = 400;
    cursor_blink = true;
    current_line_highlight = "all";
    show_whitespaces = "selection";
    centered_layout = {
      left_padding = 0.2;
      right_padding = 0.2;
    };
    active_pane_magnification = 1.0;
    scroll_beyond_last_line = "one_page";
    vertical_scroll_margin = 3;
    scroll_sensitivity = 1.0;
    relative_line_numbers = false;
    show_wrap_guides = true;
    wrap_guides = [
      80
      100
      120
    ];

    #> UI Appearance
    ui_font_family = ".SystemUIFont";
    ui_font_fallbacks = [ ];
    ui_font_features.calt = false;
    ui_font_weight = 400;
    ui_font_size = 16;
    unnecessary_code_fade = 0.5;
    toolbar = {
      breadcrumbs = true;
      quick_actions = true;
      selections_menu = true;
    };
    show_call_status_icon = true;
    tab_bar = {
      show = true;
      show_nav_history_buttons = true;
    };
    tabs = {
      git_status = false;
      close_position = "right";
      file_icons = false;
    };
    preview_tabs = {
      enabled = true;
      enable_preview_from_file_finder = true;
      enable_preview_from_code_navigation = true;
    };

    #> Editor Behavior
    base_keymap = "VSCode";
    pane_split_direction_horizontal = "up";
    pane_split_direction_vertical = "left";
    multi_cursor_modifier = "alt";
    hover_popover_enabled = true;
    confirm_quit = false;
    restore_on_startup = "last_session";
    drop_target_size = 0.2;
    when_closing_with_no_tabs = "platform_default";
    middle_click_paste = true;
    double_click_in_multibuffer = "select";
    expand_excerpt_lines = 3;
    use_system_path_prompts = true;
    redact_private_values = false;
    private_files = [
      "**/.env*"
      "**/*.pem"
      "**/*.key"
      "**/*.cert"
      "**/*.crt"
      "**/secrets.yml"
    ];
    search_wrap = true;
    search = {
      whole_word = false;
      case_sensitive = false;
      include_ignored = false;
      regex = false;
    };
    seed_search_query_from_cursor = "always";
    use_smartcase_search = false;

    #> Code Editing
    use_autoclose = true;
    use_auto_surround = true;
    always_treat_brackets_as_autoclosed = false;
    show_completions_on_input = true;
    show_completion_documentation = true;
    completion_documentation_secondary_query_debounce = 300;
    auto_signature_help = true;
    show_signature_help_after_edits = true;
    use_on_type_format = true;
    extend_comment_on_newline = true;
    show_edit_predictions = true;
    linked_edits = true;
    features.edit_prediction_provider = "zed";
    edit_predictions.disabled_globs = [ ".env" ];

    #> Gutter & Visualizations
    gutter = {
      line_numbers = true;
      code_actions = true;
      runnables = true;
      folds = true;
    };
    indent_guides = {
      enabled = true;
      line_width = 1;
      active_line_width = 1;
      coloring = "indent_aware";
      background_coloring = "indent_aware";
    };
    scrollbar = {
      show = "auto";
      cursors = true;
      git_diff = true;
      search_results = true;
      selected_symbol = true;
      diagnostics = "all";
    };
    inlay_hints = {
      enabled = true;
      show_type_hints = true;
      show_parameter_hints = true;
      show_other_hints = true;
      show_background = true;
      edit_debounce_ms = 700;
      scroll_debounce_ms = 50;
    };
    line_indicator_format = "long";

    #> Panels & Sidebars
    project_panel = {
      button = true;
      default_width = 240;
      dock = "left";
      file_icons = true;
      folder_icons = true;
      git_status = true;
      indent_size = 20;
      auto_reveal_entries = true;
      auto_fold_dirs = true;
      scrollbar.show = null;
    };
    outline_panel = {
      button = true;
      default_width = 300;
      dock = "left";
      file_icons = true;
      folder_icons = true;
      git_status = true;
      indent_size = 20;
      auto_reveal_entries = true;
      auto_fold_dirs = true;
    };
    collaboration_panel = {
      button = true;
      dock = "left";
      default_width = 240;
    };
    chat_panel = {
      button = "always";
      dock = "right";
      default_width = 240;
    };
    notification_panel = {
      button = true;
      dock = "right";
      default_width = 380;
    };
    file_finder = {
      file_icons = true;
      modal_max_width = "small";
    };

    #> Terminal Settings
    terminal = {
      shell = "system";
      dock = "bottom";
      default_width = 640;
      default_height = 240;
      font_size = 16;
      working_directory = "current_project_directory";
      blinking = "terminal_controlled";
      alternate_scroll = "off";
      option_as_meta = true;
      copy_on_select = true;
      button = false;
      env = { };
      line_height = "standard";
      toolbar = {
        title = true;
        buttons = false;
      };
    };

    #> AI & Assistant Features
    assistant = {
      version = "2";
      enabled = true;
      button = true;
      dock = "bottom";
      default_width = 640;
      default_height = 320;
      default_model = {
        provider = "ollama";
        model = "qwen2.5-coder:latest";
      };
    };
    language_models = {
      anthropic.version = "1";
      anthropic.api_url = "https://api.anthropic.com";
      google.api_url = "https://generativelanguage.googleapis.com";
      ollama = {
        api_url = "http://localhost:11434";
        low_speed_timeout_in_seconds = 60;
      };
      openai = {
        version = "1";
        api_url = "https://api.openai.com/v1";
        low_speed_timeout_in_seconds = 600;
      };
    };
    slash_commands = {
      docs.enabled = false;
      project.enabled = false;
    };
    message_editor.auto_replace_emoji_shortcode = true;

    #> File Handling & Formatting
    remove_trailing_whitespace_on_save = true;
    ensure_final_newline_on_save = true;
    format_on_save = "on";
    formatter = "auto";
    soft_wrap = "editor_width";
    preferred_line_length = 80;
    hard_tabs = false;
    tab_size = 2;
    autosave.after_delay.milliseconds = 500;
    file_scan_exclusions = [
      "**/.git"
      "**/.svn"
      "**/.hg"
      "**/CVS"
      "**/.DS_Store"
      "**/Thumbs.db"
      "**/.classpath"
      "**/.settings"
      "**/.direnv"
      "**/.devenv"
      "**/result"
      "**/.trunk"
      "**/.Trash-1000"
      "$RECYCLE.BIN"
      "System Volume Information"
    ];
    file_types = {
      "Plain Text" = [ "txt" ];
      "JavaScript" = [ "*.gs" ];
      "JSON" = [
        "flake.lock"
        "package-lock.json"
        "yarn.lock"
        "pnpm-lock.yaml"
      ];
      "JSONC" = [
        "**/.zed/**/*.json"
        "**/zed/**/*.json"
        "**/Zed/**/*.json"
        "**/.vscode/**/*.json"
        "**/vscode/**/*.json"
        "**/VSCode/**/*.json"
        "tsconfig.json"
        "tsconfig.*.json"
        "jsconfig.json"
        "jsconfig.*.json"
        "pyrightconfig.json"
        ".eslintrc.json"
        ".prettierrc.json"
        ".babelrc.json"
        "omnisharp.json"
        "launch.json"
        "settings.json"
      ];
    };

    #> Language Integrations
    enable_language_server = true;
    language_servers = [ "..." ];
    languages = { };
    jupyter.enabled = true;
    code_actions_on_format = { };

    #> Git Integration
    git = {
      git_gutter = "tracked_files";
      inline_blame.enabled = true;
    };

    #> Collaboration & Communication
    calls = {
      mute_on_join = false;
      share_on_join = false;
    };

    #> Vim Configuration
    vim_mode = false;
    vim = {
      toggle_relative_line_numbers = false;
      use_system_clipboard = "always";
      use_multiline_find = false;
      use_smartcase_find = false;
      custom_digraphs = { };
    };

    #> Misc Settings
    diagnostics.include_warnings = true;
    load_direnv = "shell_hook";
    journal = {
      path = "~";
      hour_format = "hour12";
    };
    task.show_status_indicator = true;
    tasks.variables = { };
    telemetry = {
      diagnostics = true;
      metrics = true;
    };
    auto_update = false;
  };
}
