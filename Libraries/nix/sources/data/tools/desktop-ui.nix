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
    target = "dankcalendar";
  };

  ghostty = mkSource {
    categories = ["desktop-ui" "terminal"];
    description = "GPU-accelerated terminal emulator";
    aliases = let
      #? Drops blanks, strips indentation, dedupes in original order.
      fontFilter = ''NF{sub(/^[[:space:]]+/,"")} NF && !seen[$0]++'';

      cmd = "ghostty";
      mk = alias: mkAlias cmd alias;
      FontsList = {
        args = ["+list-fonts"];
        pipe = [["awk" fontFilter]];
        description = "print deduplicated ${cmd} fonts";
      };
      Fonts = {
        args = ["+list-fonts"];
        pipe = [["awk" fontFilter] ["bat" "--style=numbers"]];
        description = "browse fonts available to ${cmd} in the bat pager";
      };
      FontsSearch = {
        args = ["+list-fonts"];
        pipe = [["awk" fontFilter] ["rg" "-i"]];
        description = "search fonts available to ${cmd}, e.g. list-fonts-search nerd";
      };
    in
      mergeDisjoint [
        {
          list-fonts = mk Fonts;
          list-fonts-print = mk FontsList;
          list-fonts-search = mk FontsSearch;
        }
        (mkAliasFamily cmd {inherit Fonts FontsList FontsSearch;})
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
          copy = mk Clipboard;
          paste = mk ClipboardPaste;
          copy-primary = mk ClipboardPrimary;
          paste-primary = mk ClipboardPastePrimary;
          clipboard-formats = mk ClipboardFormats;
          paste-image = mk ClipboardSaveImage;
          icat = mk Icat;
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
