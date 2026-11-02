{
  mergeDisjoint,
  mkAlias,
  mkAliasFamily,
  mkSource,
  replaceStrings,
  ...
}: {
  dms-shell = mkSource {
    categories = ["desktop-ui"];
    description = "Dank Material Shell";
    input = "dank-material-shell";
    aliases = mkAliasFamily "dms" {
      Call = {args = ["ipc" "call"];};
      Set = {args = ["ipc" "call" "settings" "set"];};
    };
    transform = {
      package,
      source,
      builders,
      ...
    }: let
      patchedSource = builders.applyPatches {
        name = "dms-patched-source";
        src = source;
        patches = [
          ../../patches/dms/theme-control.patch
          ../../patches/dms/catppuccin-matugen.patch
          ../../patches/dms/notification-scratchpad-activation.patch
        ];
      };
    in
      package.overrideAttrs (previous: {
        src = "${patchedSource}/core";
        postInstall =
          replaceStrings
          [source]
          ["${patchedSource}"]
          previous.postInstall;
        passthru =
          (previous.passthru or {})
          // {shellSource = "${patchedSource}/quickshell";};
      });
  };

  dux-calendar = mkSource {
    categories = ["desktop-ui"];
    description = "Dux Calendar";
    target = "dux-calendar";
  };

  ghostty = mkSource {
    categories = ["desktop-ui" "terminal"];
    description = "GPU-accelerated terminal emulator";
    aliases = let
      #? Drops blanks, strips indentation, dedupes in original order.
      fontFilter = ''NF{sub(/^[[:space:]]+/,"")} NF && !seen[$0]++'';

      cmd = "ghostty";
      mk = alias: mkAlias cmd alias;

      #? Builds the print / pager / search trio for any list-style action.
      mkListTrio = {
        action,
        noun,
        example,
        filter ? [],
      }: {
        print = {
          args = [action];
          pipe = filter;
          description = "print ${noun} known to ${cmd}";
        };
        page = {
          args = [action];
          pipe = filter ++ [["bat" "--style=numbers"]];
          description = "browse ${noun} known to ${cmd} in the bat pager";
        };
        search = {
          args = [action];
          pipe = filter ++ [["rg" "-i"]];
          description = "search ${noun} known to ${cmd}, e.g. ${example}";
        };
      };

      fonts = mkListTrio {
        action = "+list-fonts";
        noun = "fonts";
        example = "list-fonts-search nerd";
        filter = [["awk" fontFilter]];
      };
      keybinds = mkListTrio {
        action = "+list-keybinds";
        noun = "keybinds";
        example = "list-keybinds-search split";
      };
      themes = mkListTrio {
        action = "+list-themes";
        noun = "themes";
        example = "list-themes-search catppuccin";
      };
      colors = mkListTrio {
        action = "+list-colors";
        noun = "named colors";
        example = "list-colors-search blue";
      };
      actions = mkListTrio {
        action = "+list-actions";
        noun = "keybind actions";
        example = "list-actions-search tab";
      };

      Fonts = fonts.page;
      FontsList = fonts.print;
      FontsSearch = fonts.search;
      Keybinds = keybinds.page;
      KeybindsList = keybinds.print;
      KeybindsSearch = keybinds.search;
      Themes = themes.page;
      ThemesList = themes.print;
      ThemesSearch = themes.search;
      Colors = colors.page;
      ColorsList = colors.print;
      ColorsSearch = colors.search;
      Actions = actions.page;
      ActionsList = actions.print;
      ActionsSearch = actions.search;

      Version = {
        args = ["+version"];
        description = "show ghostty version and build info";
      };
      EditConfig = {
        args = ["+edit-config"];
        description = "open the ghostty config in $EDITOR";
      };
      ShowConfig = {
        args = ["+show-config"];
        pipe = [["bat" "--language=ini" "--style=numbers"]];
        description = "show the effective ghostty config in the bat pager";
      };
      ShowConfigDefault = {
        args = ["+show-config" "--default"];
        pipe = [["bat" "--language=ini" "--style=numbers"]];
        description = "show ghostty's default config in the bat pager";
      };
      ShowConfigDocs = {
        args = ["+show-config" "--default" "--docs"];
        pipe = [["bat" "--language=ini" "--style=numbers"]];
        description = "show the default config with documentation comments";
      };
      ValidateConfig = {
        args = ["+validate-config"];
        description = "check the ghostty config for errors";
      };
      ShowFace = {
        args = ["+show-face"];
        description = "show which font face renders a codepoint";
      };
      SshCache = {
        args = ["+ssh-cache"];
        description = "manage the ghostty ssh terminfo cache";
      };
      CrashReport = {
        args = ["+crash-report"];
        description = "list or inspect ghostty crash reports";
      };
      NewWindow = {
        args = ["+new-window"];
        description = "open a new window in the running ghostty instance";
      };
      Boo = {
        args = ["+boo"];
        description = "ghostty easter egg animation";
      };
    in
      mergeDisjoint [
        {
          list-fonts = mk Fonts;
          list-fonts-print = mk FontsList;
          list-fonts-search = mk FontsSearch;

          list-keybinds = mk Keybinds;
          list-keybinds-print = mk KeybindsList;
          list-keybinds-search = mk KeybindsSearch;

          list-themes = mk Themes;
          list-themes-print = mk ThemesList;
          list-themes-search = mk ThemesSearch;

          list-colors = mk Colors;
          list-colors-print = mk ColorsList;
          list-colors-search = mk ColorsSearch;

          list-actions = mk Actions;
          list-actions-print = mk ActionsList;
          list-actions-search = mk ActionsSearch;

          ghostty-config = mk ShowConfig;
          ghostty-config-default = mk ShowConfigDefault;
          ghostty-config-docs = mk ShowConfigDocs;
          ghostty-edit = mk EditConfig;
          ghostty-validate = mk ValidateConfig;
          ghostty-face = mk ShowFace;
        }
        (mkAliasFamily cmd {
          inherit
            Fonts
            FontsList
            FontsSearch
            Keybinds
            KeybindsList
            KeybindsSearch
            Themes
            ThemesList
            ThemesSearch
            Colors
            ColorsList
            ColorsSearch
            Actions
            ActionsList
            ActionsSearch
            Version
            EditConfig
            ShowConfig
            ShowConfigDefault
            ShowConfigDocs
            ValidateConfig
            ShowFace
            SshCache
            CrashReport
            NewWindow
            Boo
            ;
        })
      ];
  };

  kitty = mkSource {
    categories = ["desktop-ui" "terminal"];
    description = "GPU-accelerated terminal emulator with graphics support";
    aliases = let
      cmd = "kitten";
      mk = alias: mkAlias cmd alias;

      Clipboard = {
        args = ["clipboard"];
        description = "copy stdin or files (text, images) to the system clipboard";
      };
      ClipboardPaste = {
        args = ["clipboard" "--get-clipboard"];
        description = "paste the system clipboard to stdout";
      };
      ClipboardPrimary = {
        args = ["clipboard" "--use-primary"];
        description = "copy stdin or files to the primary selection";
      };
      ClipboardPastePrimary = {
        args = ["clipboard" "--get-clipboard" "--use-primary"];
        description = "paste the primary selection to stdout";
      };
      ClipboardFormats = {
        args = ["clipboard" "--get-clipboard" "--mime" "." "/dev/stdout"];
        description = "list the MIME types currently on the clipboard";
      };
      ClipboardSaveImage = {
        args = ["clipboard" "--get-clipboard"];
        description = "save a clipboard image to a file, e.g. paste-image shot.png";
      };
      Icat = {
        args = ["icat"];
        description = "display images in the terminal";
      };
      Diff = {
        args = ["diff"];
        description = "side-by-side diff of files and images";
      };
      Ssh = {
        args = ["ssh"];
        description = "ssh with kitty shell integration and file copying";
      };
      Themes = {
        args = ["themes"];
        description = "browse and apply kitty color schemes";
      };
      ChooseFonts = {
        args = ["choose-fonts"];
        description = "interactively choose kitty fonts";
      };
      ChooseFiles = {
        args = ["choose-files"];
        description = "fuzzy file chooser";
      };
      CommandPalette = {
        args = ["command-palette"];
        description = "browse and trigger keyboard shortcuts and actions";
      };
      Hints = {
        args = ["hints"];
        description = "select text from the screen with the keyboard";
      };
      UnicodeInput = {
        args = ["unicode-input"];
        description = "browse and select unicode characters by name";
      };
      Notify = {
        args = ["notify"];
        description = "send a desktop notification";
      };
      Ask = {
        args = ["ask"];
        description = "ask the user for input";
      };
      Remote = {
        args = ["@"];
        description = "control kitty remotely";
      };
      EditInKitty = {
        args = ["edit-in-kitty"];
        description = "edit a file in a kitty overlay window";
      };
      Transfer = {
        args = ["transfer"];
        description = "transfer files over the TTY";
      };
      Broadcast = {
        args = ["broadcast"];
        description = "broadcast typed text to kitty windows";
      };
      ShowKey = {
        args = ["show-key"];
        description = "show key codes the terminal generates";
      };
      QueryTerminal = {
        args = ["query-terminal"];
        description = "query terminal capabilities";
      };
      ResizeWindow = {
        args = ["resize-window"];
        description = "resize the current window interactively";
      };
      HyperlinkedGrep = {
        args = ["hyperlinked-grep"];
        description = "ripgrep with clickable hyperlinks in the output";
      };
      UpdateSelf = {
        args = ["update-self"];
        description = "update the kitten binary";
      };
    in
      mergeDisjoint [
        {
          kcopy = mk Clipboard;
          kpaste = mk ClipboardPaste;
          kcopy-primary = mk ClipboardPrimary;
          kpaste-primary = mk ClipboardPastePrimary;
          kclipboard-formats = mk ClipboardFormats;
          kpaste-image = mk ClipboardSaveImage;
          kicat = mk Icat;
          kdiff = mk Diff;
          kssh = mk Ssh;
          kthemes = mk Themes;
          kfonts = mk ChooseFonts;
          kfiles = mk ChooseFiles;
          kpalette = mk CommandPalette;
          khints = mk Hints;
          kunicode = mk UnicodeInput;
          kremote = mk Remote;
          krg = mk HyperlinkedGrep;
        }
        (mkAliasFamily cmd {
          inherit
            Clipboard
            ClipboardPaste
            ClipboardPrimary
            ClipboardPastePrimary
            ClipboardFormats
            ClipboardSaveImage
            Icat
            Diff
            Ssh
            Themes
            ChooseFonts
            ChooseFiles
            CommandPalette
            Hints
            UnicodeInput
            Notify
            Ask
            Remote
            EditInKitty
            Transfer
            Broadcast
            ShowKey
            QueryTerminal
            ResizeWindow
            HyperlinkedGrep
            UpdateSelf
            ;
        })
      ];
  };

  foot = mkSource {
    categories = ["desktop-ui" "terminal"];
    description = "lightweight Wayland terminal emulator";
  };

  warp-terminal = mkSource {
    categories = ["desktop-ui" "terminal"];
    description = "Warp terminal emulator";
    input = "warp-terminal";
    # exe = "warp";
  };

  nemo = mkSource {
    categories = ["desktop-ui"];
    description = "Nemo file manager with extensions";
    target = "nemo-with-extensions";
    exe = "nemo";
  };

  hyprpaper = mkSource {
    categories = ["desktop-ui"];
    description = "wallpaper daemon for Hyprland";
    aliases = mkAliasFamily "hyprpaper" {
      Config = {
        args = ["--config"];
        description = "start with a caller-specified configuration file";
      };
    };
  };

  quickshell = mkSource {
    categories = ["desktop-ui"];
    description = "QtQuick-based desktop shell";
    input = "quickshell";
    aliases = mkAliasFamily "quickshell" {
      Config = {
        args = ["--config"];
        description = "start a named configuration (caller supplies it)";
      };
      Kill = {
        args = ["kill"];
        description = "stop a running quickshell instance";
      };
      List = {
        args = ["list"];
        description = "list running quickshell instances";
      };
      Path = {
        args = ["--path"];
        description = "start from a caller-specified configuration path";
      };
    };
  };

  swaybg = mkSource {
    categories = ["desktop-ui"];
    description = "wallpaper utility for Sway";
    aliases = mkAliasFamily "swaybg" {
      Color = {
        args = ["--color"];
        description = "set a solid background color (caller supplies it)";
      };
      Fill = {
        args = ["--mode" "fill" "--image"];
        description = "set an image wallpaper scaled to fill the output (caller supplies the image)";
      };
      Image = {
        args = ["--image"];
        description = "set an image wallpaper (caller supplies the image)";
      };
    };
  };

  tmux = mkSource {
    categories = ["terminal"];
    description = "terminal multiplexer";
    aliases = let
      cmd = "tmux";
      mk = alias: mkAlias cmd alias;

      #? Builds the print / pager / search trio for any list-style command.
      mkListTrio = {
        args,
        noun,
        example,
        filter ? [],
      }: {
        print = {
          inherit args;
          pipe = filter;
          description = "print ${noun}";
        };
        page = {
          inherit args;
          pipe = filter ++ [["bat" "--style=numbers"]];
          description = "browse ${noun} in the bat pager";
        };
        search = {
          inherit args;
          pipe = filter ++ [["rg" "-i"]];
          description = "search ${noun}, e.g. ${example}";
        };
      };

      keys = mkListTrio {
        args = ["list-keys"];
        noun = "tmux key bindings";
        example = "tmux-keys-search split";
      };
      keyNotes = mkListTrio {
        args = ["list-keys" "-N"];
        noun = "described tmux key bindings";
        example = "tmux-keynotes-search pane";
      };
      commands = mkListTrio {
        args = ["list-commands"];
        noun = "tmux commands";
        example = "tmux-commands-search window";
      };
      options = mkListTrio {
        args = ["show-options" "-g"];
        noun = "global tmux options";
        example = "tmux-options-search mouse";
      };
      windowOptions = mkListTrio {
        args = ["show-window-options" "-g"];
        noun = "global tmux window options";
        example = "tmux-window-options-search mode";
      };

      Keys = keys.page;
      KeysList = keys.print;
      KeysSearch = keys.search;
      KeyNotes = keyNotes.page;
      KeyNotesList = keyNotes.print;
      KeyNotesSearch = keyNotes.search;
      Commands = commands.page;
      CommandsList = commands.print;
      CommandsSearch = commands.search;
      Options = options.page;
      OptionsList = options.print;
      OptionsSearch = options.search;
      WindowOptions = windowOptions.page;
      WindowOptionsList = windowOptions.print;
      WindowOptionsSearch = windowOptions.search;

      NewSession = {
        args = ["new-session" "-A" "-s"];
        description = "attach to a named session, creating it if missing, e.g. tn main";
      };
      Attach = {
        args = ["attach-session"];
        description = "attach to the last session, or pass -t name";
      };
      KillSession = {
        args = ["kill-session" "-t"];
        description = "kill a session by name, e.g. tkill scratch";
      };
      KillServer = {
        args = ["kill-server"];
        description = "kill the tmux server and every session";
      };
      Sessions = {
        args = ["list-sessions"];
        description = "list sessions";
      };
      Windows = {
        args = ["list-windows" "-a"];
        description = "list windows across all sessions";
      };
      Panes = {
        args = ["list-panes" "-a"];
        description = "list panes across all sessions";
      };
      Clients = {
        args = ["list-clients"];
        description = "list attached clients";
      };
      Buffers = {
        args = ["list-buffers"];
        description = "list paste buffers";
      };
      ShowBuffer = {
        args = ["show-buffer"];
        description = "print the most recent paste buffer";
      };
      Environment = {
        args = ["show-environment" "-g"];
        description = "show the global tmux environment";
      };
      Capture = {
        args = ["capture-pane" "-p" "-S" "-"];
        description = "print the current pane's full scrollback to stdout";
      };
      Info = {
        args = ["info"];
        pipe = [["bat" "--style=numbers"]];
        description = "show tmux server, terminal and feature info in the bat pager";
      };
      SourceFile = {
        args = ["source-file"];
        description = "load a config file into the running server, e.g. tsource ~/.config/tmux/tmux.conf";
      };
      DisplayMessage = {
        args = ["display-message" "-p"];
        description = "print a format string, e.g. tmux-fmt '#{session_name}'";
      };
    in
      mergeDisjoint [
        {
          tmux-keys = mk Keys;
          tmux-keys-print = mk KeysList;
          tmux-keys-search = mk KeysSearch;

          tmux-keynotes = mk KeyNotes;
          tmux-keynotes-print = mk KeyNotesList;
          tmux-keynotes-search = mk KeyNotesSearch;

          tmux-commands = mk Commands;
          tmux-commands-print = mk CommandsList;
          tmux-commands-search = mk CommandsSearch;

          tmux-options = mk Options;
          tmux-options-print = mk OptionsList;
          tmux-options-search = mk OptionsSearch;

          tmux-window-options = mk WindowOptions;
          tmux-window-options-print = mk WindowOptionsList;
          tmux-window-options-search = mk WindowOptionsSearch;

          tn = mk NewSession;
          ta = mk Attach;
          tkill = mk KillSession;
          tls = mk Sessions;
          tmux-windows = mk Windows;
          tmux-panes = mk Panes;
          tmux-capture = mk Capture;
          tmux-info = mk Info;
          tsource = mk SourceFile;
          tmux-fmt = mk DisplayMessage;
        }
        (mkAliasFamily cmd {
          inherit
            Keys
            KeysList
            KeysSearch
            KeyNotes
            KeyNotesList
            KeyNotesSearch
            Commands
            CommandsList
            CommandsSearch
            Options
            OptionsList
            OptionsSearch
            WindowOptions
            WindowOptionsList
            WindowOptionsSearch
            NewSession
            Attach
            KillSession
            KillServer
            Sessions
            Windows
            Panes
            Clients
            Buffers
            ShowBuffer
            Environment
            Capture
            Info
            SourceFile
            DisplayMessage
            ;
        })
      ];
  };

  variety = mkSource {
    categories = ["desktop-ui"];
    description = "wallpaper changer with scheduling and effects";
    aliases = mkAliasFamily "variety" {
      Favorite = {
        args = ["--favorite"];
        description = "move the current wallpaper to favorites";
      };
      Next = {
        args = ["--next"];
        description = "switch to the next wallpaper";
      };
      Preferences = {
        args = ["--preferences"];
        description = "open the preferences window";
      };
      Previous = {
        args = ["--previous"];
        description = "switch to the previous wallpaper";
      };
      Quit = {
        args = ["--quit"];
        description = "quit the running instance";
      };
      TogglePause = {
        args = ["--toggle-pause"];
        description = "pause or resume wallpaper changes";
      };
      Trash = {
        args = ["--trash"];
        description = "move the current wallpaper to the trash";
      };
    };
  };
}
