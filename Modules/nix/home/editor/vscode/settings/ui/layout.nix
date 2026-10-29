_: {
  extensions = ["rebornix.toggle"];

  keybindings = [
    {
      key = "ctrl+t ctrl+m";
      command = "workbench.action.toggleMaximizedPanel";
    }
    {
      key = "ctrl+0";
      command = "runCommands";
      args = {
        commands = [
          "editor.action.fontZoomReset"
          "workbench.action.zoomReset"
        ];
      };
      when = "editorTextFocus";
    }
    {
      key = "ctrl+alt+z";
      command = "toggle";
      when = "editorTextFocus";
      args = {
        id = "zen";
        value = [
          {
            #TODO: Make it so that setting in keybingings can be defined nix-style
            "breadcrumbs.enabled" = true;
            "editor.folding" = true;
            "editor.glyphMargin" = true;
            "editor.lineNumbers" = "on";
            "editor.minimap.enabled" = true;
            "editor.scrollbar.horizontal" = "auto";
            "editor.scrollbar.vertical" = "auto";
            "window.customTitleBarVisibility" = "auto";
            "workbench.activityBar.location" = "default";
            "workbench.editor.showTabs" = "multiple";
            "workbench.statusBar.visible" = true;
          }
          {
            "breadcrumbs.enabled" = false;
            "editor.folding" = false;
            "editor.glyphMargin" = false;
            "editor.lineNumbers" = "off";
            "editor.minimap.enabled" = false;
            "editor.scrollbar.horizontal" = "hidden";
            "editor.scrollbar.vertical" = "hidden";
            "window.customTitleBarVisibility" = "never";
            "workbench.activityBar.location" = "hidden";
            "workbench.editor.showTabs" = "none";
            "workbench.statusBar.visible" = false;
          }
        ];
      };
    }
  ];

  settings = {
    #~@ Breadcrumbs for Navigation
    breadcrumbs = {
      #! overridden (default: false)
      enabled = true;
      #> How file paths appear in breadcrumbs.
      #?  - on | off | last
      filePath = "on";
      #> Show icons in breadcrumbs.
      icons = true;
      #> Show editor-type dropdown when multiple editors can open the file.
      showEditorType = true;
      #> Symbol path in breadcrumbs (`on` | `off` | `last`).
      symbolPath = "on";
      #> Symbol path separator when copying breadcrumb paths.
      symbolPathSeparator = ".";
      #> Symbol outline sort order.
      #?  - position | name | type
      symbolSortOrder = "position";
    };

    #~@ Window
    window = {
      #> Menu bar style.
      #?  - classic | visible | toggle | hidden | compact
      #! overridden (default: "classic")
      menuBarVisibility = "toggle";
      #> Custom title bar style (`native` | `custom`).
      #! overridden (default: "native")
      titleBarStyle = "native";
      #> Custom title bar visibility.
      #? - auto | windowed | never
      #! overridden (default: "auto")
      customTitleBarVisibility = "auto";
      #> Alt-key focuses the menu bar.
      #! overridden (default: true)
      customMenuBarAltFocus = true;
      #> Restore to fullscreen if exited in fullscreen.
      #! overridden (default: false)
      restoreFullscreen = true;
      #> Reopen the last active project when starting without a path.
      restoreWindows = "one";
      #> Zoom per window vs global.
      #! overridden (default: false)
      zoomPerWindow = true;
      #> Command centre in the title bar.
      commandCenter = true;
      #> Menu style (`custom` | `native` | `inherit`).
      menuStyle = "inherit";
      #> Window controls style (`native` | `custom` | `hidden`).
      controlsStyle = "native";
      #> Dialog style (`native` | `custom`).
      dialogStyle = "native";
      #> Double-click title bar icon to close.
      doubleClickIconToClose = false;
      #> Open files in a new window (`on` | `off` | `default`).
      openFilesInNewWindow = "off";
      #> Open folders in a new window (`on` | `off` | `default`).
      openFoldersInNewWindow = "default";
      #> New window dimensions.
      #?  - default | inherit | offset | maximized | fullscreen
      newWindowDimensions = "default";

      #~@ Layout density
      #> Editor tab height (`default` | `compact`).
      density.editorTabHeight = "default";
    };

    workbench = {
      activityBar = {
        #~@ Activity bar & side bar
        #> Where the Activity Bar sits relative to the side bars.
        #?  - default: Side of the Primary Side Bar, above the Secondary.
        #?  - top | bottom | hidden
        location = "default";
        #> Auto-hide the Activity Bar when only one view container is shown.
        autoHide = false;
        #> Compact Activity Bar layout (smaller icons, narrower).
        compact = false;
        #> Click behaviour on Activity Bar icons.
        #?  - toggle | focus
        iconClickBehavior = "toggle";
      };
      #> Primary side bar location (`left` | `right`).
      #! overridden (default: "left")
      sideBar.location = "right";

      secondarySideBar = {
        #~@ Secondary side bar
        #> Default visibility of the secondary side bar in new windows.
        #?  - hidden | visibleInWorkspace | visible
        #?  - maximizedInWorkspace | maximized
        defaultVisibility = "visibleInWorkspace";
        #> Force secondary side bar maximized on startup / no open editors.
        forceMaximized = false;
      };

      panel = {
        #~@ Panel
        #> Default location of the panel (terminal, output, problems, …).
        #?  - bottom | top | left | right
        defaultLocation = "bottom";
        #> Whether the panel opens maximized.
        #?  - always | never | preserve
        opensMaximized = "preserve";
        #> Show labels (not icons) for panel title actions.
        showLabels = true;
      };

      #~@ Status Bar
      statusBar.visible = true;

      #~@ Editor tabs
      #> What to show when no editor is open.
      #?  - none | welcomePage | readme | newUntitledFile
      #?  - welcomePageInEmptyWorkbench | terminal
      #! overridden (default: "welcomePage")
      startupEditor = "none";

      editor = {
        #> How editor tabs are shown.
        #?  - multiple | single | none
        showTabs = "multiple";
        #> Reveal an already-open editor instead of opening another.
        #! overridden (default: false)
        revealIfOpen = true;
        #> Show hint text when the editor is empty.
        #?  - hidden | text | watermark
        #! overridden (default: "text")
        empty.hint = "hidden";
        #> Where new editors open.
        #?  - left | right | first | last
        openPositioning = "right";
        #> Direction for split-side editors.
        #?  - right | down
        openSideBySideDirection = "right";
        #> Enable preview editors (italic tab; replaced on next open).
        enablePreview = true;
        #> Preview editors opened from Quick Open.
        enablePreviewFromQuickOpen = false;
        #> Preview editors opened via code navigation.
        enablePreviewFromCodeNavigation = false;
        #> Whether to use modal editors (`off` | `some` | `all`).
        #! overridden (default: "some")
        useModal = "off";
        #> Pinned tab size (`normal` | `compact` | `shrink`).
        pinnedTabSizing = "normal";
        #> Pinned tabs on a separate row.
        pinnedTabsOnSeparateRow = false;
        #> Size of editor tabs (`fit` | `shrink` | `fixed`).
        tabSizing = "fit";
        #> Max width for `tabSizing = "fixed"`.
        tabSizingFixedMaxWidth = 160;
        #> Min width for `tabSizing = "fixed"`.
        tabSizingFixedMinWidth = 50;
        #> Show close button on tabs.
        tabActionCloseVisibility = true;
        #> Show unpin button on tabs.
        tabActionUnpinVisibility = true;
        #> Tab action button position (`left` | `right`).
        tabActionLocation = "right";
        #> Wrap tabs to multiple lines instead of a scrollbar.
        wrapTabs = false;
        #> Scroll over tabs switches editors.
        scrollToSwitchTabs = false;
        #> What clicking `×` closes.
        #?  - keyboardAndMouse | keyboard | mouse | never
        preventPinnedEditorClose = "keyboardAndMouse";
        #> Show tab icons (requires an icon theme).
        showIcons = true;
        #> Show tab index number.
        showTabIndex = false;
        #> Highlight tabs with unsaved changes (border on top).
        highlightModifiedTabs = false;
        #> Label format for editor tabs.
        #?  - default | short | medium | long
        labelFormat = "default";
        #> Direction of split editors within a group.
        #?  - vertical | horizontal
        splitInGroupLayout = "horizontal";
        #> Split sizing (`auto` | `distribute` | `split`).
        splitSizing = "auto";
        #> Restore last editor view state on reopen.
        restoreViewState = true;
        #> Restore editors on startup.
        restoreEditors = true;
        #> Focus most-recently used editor after close.
        focusRecentEditorAfterClose = true;

        #~@ Editor Groups
        #> Close empty editor groups.
        closeEmptyGroups = true;

        limit = {
          #> Limit open editors.
          enabled = false;
          #> Limit per editor group (vs across all).
          perEditorGroup = false;
          #> Limit value.
          value = 10;
        };
      };

      commandPalette = {
        #~@ Command Palette & Quick Open
        #> Preserve typed input in the command palette.
        #! overridden (default: false)
        preserveInput = true;
        #> Command palette history size (0 = disabled).
        history = 50;
        #> Show natural-language search in the command palette.
        experimental.enableNaturalLanguageSearch = true;
        #> Show "Ask in Chat" in the command palette.
        showAskInChat = true;
      };

      quickOpen = {
        #> Preserve typed input in Quick Open.
        #! overridden (default: false)
        preserveInput = true;
        #> Close Quick Open when it loses focus.
        closeOnFocusLost = true;
      };

      tree = {
        #~@ Trees & Lists
        #> Sticky scroll in trees.
        #! overridden (default: true)
        enableStickyScroll = false;
        #> Tree indent (px).
        indent = 8;
        #> Indent guides (`none` | `onHover` | `always`).
        renderIndentGuides = "onHover";
        #> Sticky tree item count.
        stickyScrollMaxItemCount = 7;
        #> Expand folders on single or double click.
        #?  - singleClick | doubleClick
        expandMode = "singleClick";
      };

      list = {
        #> Keyboard navigation for lists/trees.
        #?  - simple | highlight | filter
        #! Deprecated
        # keyboardNavigation = "highlight";
        #> Default find mode for lists/trees.
        #?  - highlight | filter
        defaultFindMode = "highlight";
        #> Default find match type for lists/trees.
        #?  - fuzzy | contiguous
        defaultFindMatchType = "fuzzy";
        #> Multi-select modifier for lists/trees.
        #?  - ctrlCmd | alt
        multiSelectModifier = "ctrlCmd";
        #> Open mode for lists/trees (`singleClick` | `doubleClick`).
        openMode = "singleClick";
        #> Smooth scrolling in lists/trees.
        smoothScrolling = false;
        #> Horizontal scrolling in lists/trees.
        horizontalScrolling = false;
      };

      #~@ Misc
      #> Experimental: share action in the command centre.
      #! overridden (default: false)
      experimental.share.enabled = true;
    };

    #~@ Zen mode
    zenMode = {
      #> Centre layout in Zen mode.
      centerLayout = true;
      #> Full screen in Zen mode.
      fullScreen = true;
      #> Hide Activity Bar in Zen mode.
      hideActivityBar = true;
      #> Hide line numbers in Zen mode.
      hideLineNumbers = true;
      #> Hide status bar in Zen mode.
      hideStatusBar = true;
      #> Restore Zen mode on restart.
      restore = true;
      #> Show tabs in Zen mode (`multiple` | `single` | `none`).
      showTabs = "multiple";
      #> Silence non-error notifications in Zen mode.
      silentNotifications = true;
    };
    #> Ignore extension recommendations.
    #! overridden (default: false)
    extensions.ignoreRecommendations = true;
  };
}
