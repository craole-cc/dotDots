{
  context,
  mkEnable,
  requires,
  ...
}: let
  lang = "typst";
  condition = requires lang;
  enable = condition;
  options.${lang}.enable = mkEnable {inherit context condition;};

  defaultFormatter = "myriad-dreamin.tinymist";
  extensions = [defaultFormatter];

  scoped = {
    inherit defaultFormatter;
    # "editor.inlayHints.enabled" = "off";
    quickSuggestions.strings = true;
  };
  settings = {
    #> Language-scoped editor defaults for Typst documents.
    "[${lang}]".editor = scoped;
    "[${lang}-code]".editor = scoped;

    #> Italic-bold the semantic scopes tinymist emits for variable references,
    #> function calls, parameters, interpolations, tags, and keywords.
    editor.tokenColorCustomizations.textMateRules = [
      {
        scope = [
          "variable.other.typst"
          "meta.function-call.typst"
          "entity.name.function.typst"
          "variable.parameter.typst"
          "punctuation.definition.variable.typst"
          "meta.interpolation.typst"
          "entity.name.tag.typst"
          "support.function.typst"
          "keyword.other.typst"
        ];
        settings. fontStyle = "italic bold";
      }
    ];

    #> Associate `.typ` files with the language id.
    files.associations."*.typ" = lang;

    tinymist = {
      #> Show compile status in the status bar.
      compileStatus = "enable";

      completion = {
        #> Enable postfix completion (`[A].box|` → `box[A]|`).
        postfix = true;
        #> Enable UFCS-style postfix completion.
        postfixUfcs = true;
        #> Enable left-variant UFCS postfix completion.
        postfixUfcsLeft = true;
        #> Enable right-variant UFCS postfix completion.
        postfixUfcsRight = true;

        #> Symbol completion mode.
        #?  - step: Complete symbols step by step
        #?  - stepless: Complete symbols steplessly
        symbol = "step";

        #> Trigger completions on snippet placeholders. No effect unless the
        #> editor supports `editor.action.triggerSuggest`.
        triggerOnSnippetPlaceholders = false;
      };

      #> Override default word separators on startup.
      #?  - enable: Override the default word separators on startup
      #?  - disable: Do not override the default word separators on startup
      configureDefaultWordSeparator = "disable";

      #> Conversions between Typst templates and other formats.
      convertExtension = [];

      #> Handle copy-paste of resources into the editing document.
      #?  - enable: Enable copy-and-paste.
      #?  - disable: Disable copy-and-paste.
      copyAndPaste = "enable";

      #> Handle drag-and-drop of resources into the editing document.
      #?  - enable: Enable drag-and-drop.
      #?  - disable: Disable drag-and-drop.
      dragAndDrop = "enable";

      #> When to export PDFs.
      #?  - never: Never export PDFs, run typst manually.
      #?  - onSave: Export PDFs when a file is saved.
      #?  - onType: Export PDFs as you type.
      #?  - onDocumentHasTitle: (Deprecated) Export PDFs when a document has a title.
      exportPdf = "never";

      #> Export target; affects how the language server completes code.
      #?  - paged: PDF, PNG, and SVG export.
      #?  - html: HTML export.
      #?  - bundle: Bundle export.
      exportTarget = "paged";

      #> Extra font files/directories for the shared compiler environment.
      fontPaths = null;

      #> Formatter indent size (spaces).
      formatterIndentSize = 2;

      #> Formatter backend.
      #?  - disable: Formatter is not activated.
      #?  - typstyle: Use typstyle formatter.
      #?  - typstfmt: Use typstfmt formatter.
      formatterMode = "typstyle";

      #> Soft limit on characters per line for the formatter.
      formatterPrintWidth = 120;

      #> How the formatter handles prose line wrapping.
      formatterProseWrap = "none";

      #> Show inline decorations for package version status.
      inlayHints.packageVersionStatus = true;

      lint = {
        #> Enable lint checks.
        enabled = true;
        #> When to run lint checks.
        #?  - onSave: Perform lint checks on save
        #?  - onType: Perform lint checks on type
        when = "onSave";
      };

      #> Enable LSP `onEnter` for automatic insertion (e.g. `///` for comments).
      onEnterEvent = true;

      #> Paste script for resources (Typst expression or path pattern).
      onPaste = "$root/assets";

      #> Path pattern for Typst artefacts (`$root`/`$dir`/`$name` supported).
      outputPath = "";

      preview = {
        #> Show cursor indicator in preview.
        cursorIndicator = true;

        #! Deprecated; use `tinymist.fontPaths`.
        # fontPaths = [];

        #> Invert preview colors.
        invertColors = "never";

        #> Render only the visible part of the document.
        partialRendering = true;

        #> When to refresh the preview.
        #?  - onSave: Refresh preview on save
        #?  - onType: Refresh preview on type
        refresh = "onType";

        #> Scroll sync mode.
        #?  - never: Disable automatic scroll sync
        #?  - onSelectionChangeByMouse: Sync on mouse selection
        #?  - onSelectionChange: Sync on any selection change
        scrollSync = "onSelectionChangeByMouse";

        #! Ignored; use `tinymist.typstExtraArgs` for `--input`.
        # sysInputs = {};
      };

      #> Previewer selection.
      previewer = defaultFormatter;

      #> Enable preview features.
      #?  - enable: Enable preview features.
      #?  - disable: Disable preview features.
      previewFeature = "enable";

      #> Project resolution strategy.
      #?  - singleFile: Each file is its own document (like Markdown).
      #?  - lockDatabase: Track preview/compile history per workspace (like Rust).
      projectResolution = "singleFile";

      #> Render Typst elements in hover docs.
      #?  - enable: Enable render docs.
      #?  - disable: Disable render docs.
      renderDocs = "enable";

      #> Typst root for absolute paths.
      rootPath = null;

      #> Semantic tokens (LSP syntax highlighting).
      #?  - enable: Use semantic tokens
      #?  - disable: Do not use semantic tokens
      semanticTokens = "enable";

      #> Path to a local tinymist executable; `"tinymist"` looks in PATH.
      serverPath = null;

      #> How to open exported files.
      #? - "editorTab"
      #? - "systemDefault".
      showExportFileIn = "editorTab";

      #> Status bar format string. Placeholders: `{compileStatusIcon}`,
      #> `{wordCount}`, `{charCount}`, `{fileName}`. Empty hides the status bar.
      statusBarFormat = "{compileStatusIcon} {wordCount} [{fileName}]";

      #> Syntax-only mode.
      #?  - auto: Follow future heuristics (currently off).
      #?  - onPowerSaving: Enable in power-saving mode.
      #?  - enable: Always enable.
      #?  - disable: Always disable.
      syntaxOnly = "auto";

      #> Load system fonts for the shared compiler environment.
      systemFonts = true;

      #> Trace LSP communication.
      trace.server = "off";

      #> Prefix newlines after comments with the corresponding prefix.
      typingContinueCommentsOnNewline = true;

      #> CLI-shaped extra arguments to the Typst compiler.
      typstExtraArgs = [];
    };
  };
in {inherit enable extensions options settings;}
