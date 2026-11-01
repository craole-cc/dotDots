{
  mkAliasFamily,
  mkLayeredAlias,
  mkSource,
  ...
}: {
  jq = mkSource {
    categories = ["text" "scripting"];
    description = "command-line JSON processor";
    aliases = mkAliasFamily "jq" {
      c = {
        args = ["-c"];
        description = "output compact JSON";
      };
      e = {
        args = ["-e"];
        description = "set the exit status from the last output value";
      };
      f = {
        args = ["--from-file"];
        description = "read the filter from a file";
      };
      j = {
        args = ["-j"];
        description = "output raw strings without trailing newlines";
      };
      n = {
        args = ["-n"];
        description = "run without reading input";
      };
      na = {
        args = ["-n" "--arg"];
        description = "run without input and bind a caller-specified string argument";
      };
      r = {
        args = ["-r"];
        description = "output strings without JSON quotes";
      };
      RawInput = {
        args = ["-R"];
        description = "read each input line as a string";
      };
      Rr = {
        args = ["-Rr"];
        description = "read raw input lines and output raw strings";
      };
      Rs = {
        args = ["-Rs"];
        description = "read all input as a single raw string";
      };
      s = {
        args = ["-s"];
        description = "read all inputs into a single array";
      };
      SortKeys = {
        args = ["--sort-keys"];
        description = "output object keys in sorted order";
      };
    };
  };

  jaq = mkSource {
    categories = ["text" "scripting"];
    description = "jq-compatible JSON processor (Rust)";
    aliases = mkAliasFamily "jaq" {
      c = {
        args = ["-c"];
        description = "output compact JSON";
      };
      f = {
        args = ["--from-file"];
        description = "read the filter from a file";
      };
      n = {
        args = ["-n"];
        description = "run without reading input";
      };
      r = {
        args = ["-r"];
        description = "output strings without JSON quotes";
      };
      na = {
        args = ["-n" "--arg"];
        description = "run without input and bind a caller-specified string argument";
      };
      RawInput = {
        args = ["-R"];
        description = "read each input line as a string";
      };
      Rr = {
        args = ["-Rr"];
        description = "read raw input lines and output raw strings";
      };
      s = {
        args = ["-s"];
        description = "read all inputs into a single array";
      };
    };
  };

  yq-go = mkSource {
    categories = ["text" "scripting"];
    description = "portable YAML, JSON, and XML processor (Go)";
    aliases = mkAliasFamily "yq" {
      e = {
        args = ["eval"];
        description = "evaluate an expression against each file separately";
      };
      ea = {
        args = ["eval-all"];
        description = "evaluate an expression against all files together";
      };
      i = {
        args = ["--inplace"];
        description = "edit files in place";
      };
      JsonToYaml = {
        args = ["--input-format" "json" "--output-format" "yaml"];
        description = "convert JSON to YAML";
      };
      Merge = {
        args = ["eval-all" "select(fileIndex == 0) * select(fileIndex == 1)"];
        description = "deep-merge two files, with the second taking precedence";
      };
      n = {
        args = ["--null-input"];
        description = "run without reading input";
      };
      P = {
        args = ["--prettyPrint"];
        description = "pretty-print the output";
      };
      ToJson = {
        args = ["--output-format" "json"];
        description = "convert YAML to JSON";
      };
    };
  };

  ripgrep = mkSource {
    categories = ["text" "scripting"];
    description = "fast recursive grep (rg)";
    aliases = mkAliasFamily "rg" {
      i = {
        args = ["-i"];
        description = "search case-insensitively";
      };
      "0" = {
        args = ["--null"];
        description = "separate matching paths with NUL bytes";
      };
      c = {
        args = ["--count"];
        description = "count matching lines per file";
      };
      Context = {
        args = ["--context"];
        description = "show a caller-specified number of context lines around matches";
      };
      F = {
        args = ["--fixed-strings"];
        description = "match literal strings instead of regular expressions";
      };
      Files = {
        args = ["--files"];
        description = "list files that would be searched";
      };
      FilesWithout = {
        args = ["--files-without-match"];
        description = "list files that contain no matches";
      };
      Fxq = {
        args = ["-Fxq"];
        description = "quietly search for an exact fixed-string line";
      };
      g = {
        args = ["--glob"];
        description = "include or exclude paths with a caller-specified glob";
      };
      h = {
        args = ["--hidden" "--no-ignore"];
        description = "search including hidden and ignored paths";
      };
      j = {
        args = ["--json"];
        description = "output matches as JSON lines";
      };
      l = {
        args = ["--files-with-matches"];
        description = "print only the names of files with matches";
      };
      m = {
        args = ["--multiline"];
        description = "allow matches to span multiple lines";
      };
      o = {
        args = ["--only-matching"];
        description = "print only the matching part of each line";
      };
      q = {
        args = ["-q"];
        description = "search quietly and report success through the exit status";
      };
      t = {
        args = ["--type"];
        description = "search only a caller-specified file type";
      };
      TypeNot = {
        args = ["--type-not"];
        description = "skip a caller-specified file type";
      };
      v = {
        args = ["--invert-match"];
        description = "show lines that do not match";
      };
      w = {
        args = ["--word-regexp"];
        description = "match whole words only";
      };
    };
  };

  sd = mkSource {
    categories = ["text" "scripting"];
    description = "intuitive sed alternative";
    aliases = mkAliasFamily "sd" {
      f = {
        args = ["--flags"];
        description = "set regex flags such as i or m (caller supplies them)";
      };
      p = {
        args = ["--preview"];
        description = "preview replacements without writing files";
      };
      s = {
        args = ["--string-mode"];
        description = "treat the pattern as a literal string";
      };
    };
  };

  glow = mkSource {
    categories = ["text" "scripting"];
    description = "terminal Markdown reader";
    aliases = let
      cfg = {
        dark = {
          args = ["--style" "dark"];
          description = "for a dark terminal background";
        };
        light = {
          args = ["--style" "light"];
          description = "for a light terminal background";
        };
        page = {
          args = ["--pager"];
          description = "in a pager";
        };
      };
      mkGlow = mkLayeredAlias "glow" [{description = "render Markdown";}];
      mkStyleAlias = name: style: {
        ${name} = mkGlow [style];
        "${name}p" = mkGlow [style cfg.page];
      };
    in
      {glowp = mkGlow [cfg.page];}
      // (mkStyleAlias "glowDark" cfg.dark)
      // (mkStyleAlias "glowLight" cfg.light)
      // (mkStyleAlias "mdD" cfg.dark)
      // (mkStyleAlias "mdL" cfg.light);
  };
}
