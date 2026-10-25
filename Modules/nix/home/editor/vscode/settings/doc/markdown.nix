{
  context,
  mkEnable,
  ...
}: let
  lang = "markdown";
  condition = true;
  enable = condition;
  options.${lang}.enable = mkEnable {inherit context condition;};

  #? Fast Rust-based markdown linter
  defaultFormatter = "rvben.rumdl";
  extensions = [
    defaultFormatter
    #? Markdown slides (Marp)
    "marp-team.marp-vscode"
    #? Markdown editing helpers (TOC, table formatter, …)
    "yzhang.markdown-all-in-one"
    #? Convert Markdown to PDF
    "yzane.markdown-pdf"
  ];

  settings = {
    #~@ Language-scoped overrides
    "[${lang}]".editor = {inherit defaultFormatter;};
    "${lang}" = {
      #~@ markdown (built-in)
      #> Typographer-style quotes and dashes in preview.
      #! overridden (default: false)
      preview.typographer = true;
      #> Update links when files move.
      #?  - never | prompt | always
      #! overridden (default: "never")
      updateLinksOnFileMove.enabled = "always";
      #> Validate links in Markdown files.
      #! overridden (default: false)
      validate.enabled = true;

      marp = {
        #~@ Marp
        #> Sets which HTML elements within Marp Markdown are enabled in rendered slides.
        #? If the workspace is not trusted, this setting treats as always "off".
        #? - off: Disable all HTML elements, including originally allowed HTML elements by Marp.
        #? - default: Enable only selectively enabled HTML elements by Marp. _([See the list of HTML elements](https://github.com/marp-team/marp-core/blob/main/src/html/allowlist.ts))_
        #? - all: Enable all HTML elements. This setting may become the slide rendering insecure.
        html = "default";

        #> Default export format.
        #?  - pdf | html | pptx | png | jpeg
        #! overridden (default: "pdf")
        exportType = "html";

        pdf = {
          #> Add PDF note annotations from HTML comments.
          #! overridden (default: false)
          noteAnnotations = true;
          #> Where PDF outlines are generated from.
          #?  - none | headings | slides | both
          #! overridden (default: "none")
          outlines = "both";
        };
        #> Resolve relative paths strictly during export.
        #! overridden (default: false)
        strictPathResolutionDuringExport = true;
      };

      extension = {
        #~@ markdown-all-in-one
        #> Bold marker: `**` or `__`.
        bold.indicator = "**";

        completion = {
          #> Enable auto-completion.
          enabled = false;
          #> Respect VS Code `search.exclude` in completions.
          respectVscodeSearchExclude = true;
          #> Root folder for path auto-completion.
          root = "";
        };
        #> Extra supported languages (e.g. rmd, quarto).
        extraLangIds = [];
        #> Italic marker: `*` or `_`.
        italic.indicator = "*";
        #> KaTeX macros.
        "katex.macros" = {};

        list = {
          #> List indentation scheme.
          #?  - adaptive: Align sublist content with parent's content
          #?  - inherit: Use the document's configured tab size
          indentationSize = "adaptive";
          #> Candidate list markers (cycled by "Toggle list").
          toggle.candidate-markers = ["-" "*" "+" "1." "1)"];
        };
        #> Basic math support via KaTeX.
        math.enabled = true;

        orderedList = {
          #> Auto renumber ordered list markers.
          autoRenumber = true;
          #> Ordered list marker style.
          #?  - one:     Always `1.`
          #?  - ordered: Increasing numbers
          marker = "ordered";
        };
        #> Auto-open preview to the side.
        preview.autoShowPreviewToSide = false;

        print = {
          #> Convert image paths to absolute when printing.
          absoluteImgPath = true;
          #> Inline images as base64 when printing.
          imgToBase64 = false;
          #> Include VS Code's Markdown styles when printing.
          includeVscodeStylesheets = true;
          #> Print to HTML on save.
          onFileSave = false;
          #> Print to bare HTML (no stylesheets).
          pureHtml = false;
          #> Theme for exported HTML (code blocks only).
          theme = "light";
          #> Validate URLs when printing.
          validateUrls = true;
        };
        #> Show formatting buttons on the editor toolbar.
        showActionButtons = false;

        syntax = {
          #> Skip syntax decorations above this size (bytes).
          decorationFileSizeLimit = 50000;
          #> Experimental plain theme.
          plainTheme = false;
        };

        tableFormatter = {
          #> No padding on the table delimiter row.
          delimiterRowNoPadding = false;
          #> GFM table formatter.
          enabled = true;
          #> Normalize table indentation to tab-size multiples.
          normalizeIndentation = false;
        };

        theming.decoration = {
          #> Border around code spans.
          renderCodeSpan = true;
          #> (Experimental) Decorate hard line breaks.
          renderHardLineBreak = false;
          #> (Experimental) Decorate links.
          renderLink = false;
          #> (Experimental) Decorate paragraphs.
          renderParagraph = false;
          #> Strikethrough rendering.
          renderStrikethrough = true;
          #> Shade trailing whitespace.
          renderTrailingSpace = false;
        };

        toc = {
          #> TOC heading levels (`x..y`).
          levels = "1..6";
          #> Use ordered list for TOC.
          orderedList = false;
          #> Plain-text TOC (no links).
          plaintext = false;
          #> Heading-ID slugify mode.
          #?  - github | azureDevops | bitbucket-cloud | gitea | gitlab | vscode | zola
          slugifyMode = "github";
          #> Unordered-list marker for TOC (`-`, `*`, `+`).
          unorderedList.marker = "-";
          #> Auto-update TOC on save.
          updateOnSave = true;
        };
        #> Per-file headings to omit from TOC.
        "toc.omittedFromToc" = {};
      };
    };

    markdown-pdf = {
      #~@ markdown-pdf
      #> Enable `<br>` rendering for line breaks.
      #! overridden (default: false)
      breaks = true;
      #> Auto-download Chromium if no system browser is available.
      chromium.autoDownload = true;

      clip = {
        #> PNG/JPEG clip region.
        x = null;
        y = null;
        width = null;
        height = null;
      };
      #> Auto-export on save.
      convertOnSave = false;
      #> Files to skip for `convertOnSave`.
      convertOnSaveExclude = [];
      #> Print header/footer.
      #! overridden (default: true)
      displayHeaderFooter = false;
      #> Emoji rendering.
      emoji = true;
      #> Path to Chromium/Chrome. Empty = bundled.
      executablePath = "";
      #> Footer HTML template (only when displayHeaderFooter = true).
      footerTemplate = "<div style=\"font-size: 9px; margin: 0 auto;\"> <span class='pageNumber'></span> / <span class='totalPages'></span></div>";
      #> Paper format.
      #?  - Letter | Legal | Tabloid | Ledger | A0..A6
      #! overridden (default: "A4")
      format = "Letter";
      #> Header HTML template (only when displayHeaderFooter = true).
      headerTemplate = "<div style=\"font-size: 9px; margin-left: 1cm;\"> <span class='title'></span></div> <div style=\"font-size: 9px; margin-left: auto; margin-right: 1cm; \">%%ISO-DATE%%</div>";
      #> Paper height (overrides `format` when set). Units: mm, cm, in, px.
      height = "";
      #> Syntax highlighting.
      highlight = true;
      #> highlight.js stylesheet name. Empty = theme default.
      highlightStyle = "";
      #> Include VS Code's built-in Markdown styles.
      includeDefaultStyles = true;

      margin = {
        #> Page margins (mm, cm, in, px).
        top = "1.5cm";
        bottom = "1cm";
        left = "1cm";
        right = "1cm";
      };
      #> markdown-it-include support.
      markdown-it-include.enable = true;

      math = {
        #> Math rendering (KaTeX). Matches the built-in Markdown preview.
        enabled = true;
        #> KaTeX macros.
        "katex.macros" = {};
      };
      #> Mermaid renderer URL.
      mermaidServer = "https://unpkg.com/mermaid/dist/mermaid.min.js";
      #> Transparent background for PNG/JPEG.
      omitBackground = false;
      #> Orientation.
      #?  - portrait | landscape
      orientation = "portrait";
      #> Output directory (relative to workspace, or absolute).
      outputDirectory = "";
      #> Resolve `outputDirectory` relative to the file.
      outputDirectoryRelativePathFile = false;
      #> Page ranges for PDF (e.g. "1-5, 8, 11-13"). Empty = all.
      pageRanges = "";
      #> PlantUML delimiters.
      plantumlOpenMarker = "@startuml";
      plantumlCloseMarker = "@enduml";
      #> PlantUML server.
      plantumlServer = "http://www.plantuml.com/plantuml";
      #> Print background graphics.
      printBackground = true;
      #> JPEG quality (0–100).
      quality = 100;
      #> HTML sanitization.
      #?  - gfm:              Strip dangerous tags (script, iframe, style, …)
      #?  - gfm-allow-style:  Keep <style> for layout customization
      #?  - none:             No sanitization (legacy, unsafe)
      sanitize = "gfm";
      #> Page render scale.
      scale = 1;
      #> Status bar message timeout (ms).
      StatusbarMessageTimeout = 10000;
      #> Custom stylesheets (absolute paths, `\` must be escaped as `\\`).
      styles = [];
      #> Resolve styles relative to the file.
      stylesRelativePathFile = false;
      #> Output formats (any combination).
      #?  - pdf | html | png | jpeg
      type = ["pdf"];
      #> Paper width (overrides `format` when set). Units: mm, cm, in, px.
      width = "";
    };

    rumdl = {
      #~@ rumdl
      #> Path to a rumdl config file. Empty = default config discovery.
      configPath = "";
      #> Deduplicate diagnostics (useful when multiple linters are active).
      diagnostics.deduplicate = true;
      #> Enable rumdl linting.
      enable = true;
      #> Auto-fix on save. For finer control, use `editor.codeActionsOnSave`.
      fixOnSave = true;

      linkCompletions = {
        #> Content roots for absolute link completion (paths starting with `/`).
        #? Empty = workspace folders.
        contentRoots = [];
        #> Provide completions inside markdown link targets.
        enable = true;
      };
      #> Hover, go-to-def, find-refs, rename for markdown links.
      linkNavigation.enable = true;
      #> When to lint.
      #?  - onType | onSave
      lint.run = "onType";

      rules = {
        #> Rules to disable.
        disable = [];
        #> Rules to enable (if set, only these run).
        enable = [];
      };

      server = {
        #> Server log level (Output → rumdl).
        logLevel = "info";
        #> Path to rumdl binary. Empty = auto-detect (.venv → node_modules → PATH → bundled).
        path = "";
      };
      #> LSP trace.
      #?  - off | messages | verbose
      trace.server = "off";
    };

    #~@ Semantic  Colour and style for TextMate scopes.
    editor.tokenColorCustomizations.textMateRules = [
      {
        scope = [
          "markup.italic.markdown"
          "markup.quote.markdown"
        ];
        settings = {fontStyle = "italic";};
      }
    ];
  };
in {inherit enable extensions options settings;}
