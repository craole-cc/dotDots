_: {
  name = "editor";
  description = "Editor";
  enable = true;

  keybindings = [
    {
      key = "alt+up";
      command = "editor.action.moveLinesUpAction";
      when = "editorTextFocus && !editorReadonly";
    }
    {
      key = "alt+down";
      command = "editor.action.moveLinesDownAction";
      when = "editorTextFocus && !editorReadonly";
    }
    {
      key = "ctrl+c";
      command = "editor.action.clipboardCopyAction";
      when = "textInputFocus";
    }
  ];

  settings = {
    editor = {
      detectIndentation = false;
      insertSpaces = true;
      tabSize = 2;
      wordWrap = "bounded";
      wordWrapColumn = 120;
      formatOnSave = true;
      formatOnSaveMode = "file";
      folding = true;
      glyphMargin = true;
      lineNumbers = "on";
      renderControlCharacters = false;
      renderLineHighlight = "gutter";
      renderWhitespace = "all";
      scrollbar = {
        horizontal = "auto";
        vertical = "auto";
      };
      unicodeHighlight.ambiguousCharacters = false;
      minimap = {
        enabled = true;
        size = "fill";
      };

      guides = {
        #> Vertical bracket guides.
        #?  - true | active | false
        #! overridden (default: false)
        bracketPairs = "active";
        #> Horizontal bracket guides.
        #?  - true | active | false
        bracketPairsHorizontal = "active";
        #> Highlight active bracket pair.
        highlightActiveBracketPair = true;
        #> Highlight active indent guide.
        #?  - true | always | false
        highlightActiveIndentation = true;
        #> Show indent guides.
        indentation = true;
      };
      #> Highlight matching brackets.
      #?  - always | near | never
      #! overridden (default: "always")
      matchBrackets = "always";
      occurrencesHighlight = "off";
      selectionHighlight = false;
      cursorBlinking = "expand";
      cursorSmoothCaretAnimation = "on";
      mouseWheelZoom = true;
      smoothScrolling = true;
      stickyScroll = {
        defaultModel = "indentationModel";
        enabled = false;
        scrollWithEditor = false;
      };
      inlayHints.enabled = "offUnlessPressed";
      inlineSuggest.suppressSuggestions = true;
      quickSuggestions.strings = "on";
      suggestSelection = "recentlyUsedByPrefix";
      accessibilitySupport = "off";
      linkedEditing = true;
    };

    diffEditor = {
      ignoreTrimWhitespace = false;
      codeLens = true;
    };
  };
}
