{
  mkLayeredAlias,
  mkAliasFamily,
  mergeDisjoint,
  mkSource,
  mapAttrsToList,
  ...
}: {
  bat = mkSource {
    categories = ["files" "scripting"];
    description = "cat with syntax highlighting";
    aliases = mkAliasFamily "bat" {
      d = {
        args = ["--diff"];
        description = "show only lines changed relative to the git index";
      };
      l = {
        args = ["--language"];
        description = "force a syntax language (caller supplies it)";
      };
      n = {
        args = ["--number"];
        description = "show line numbers";
      };
      p = {
        args = ["--plain"];
        description = "print without decorations or syntax highlighting";
      };
      pp = {
        args = ["-pp"];
        description = "print plain without paging";
      };
      r = {
        args = ["--line-range"];
        description = "print only a caller-specified line range";
      };
    };
  };

  dust = mkSource {
    categories = ["files" "scripting"];
    description = "intuitive du (disk usage)";
    aliases = mkAliasFamily "dust" {
      d = {
        args = ["--depth"];
        description = "limit the directory depth shown, e.g. dustd 2 ~/src";
      };
      n = {
        args = ["--number-of-lines"];
        description = "show a caller-specified number of entries, e.g. dustn 100";
      };
      r = {
        args = ["--reverse"];
        description = "show the largest entries at the top";
      };
      All = {
        args = ["--number-of-lines" "1000000"];
        description = "show every entry instead of fitting the terminal height";
      };
      Apparent = {
        args = ["--apparent-size"];
        description = "rank by file length instead of disk blocks";
      };
      BigFiles = {
        args = ["--only-file" "--reverse" "--number-of-lines" "50"];
        description = "find the 50 largest files, biggest first";
      };
      Bytes = {
        args = ["--output-format" "b"];
        description = "show every size in bytes";
      };
      Collapse = {
        args = ["--collapse"];
        description = "keep a caller-specified directory collapsed, e.g. dustCollapse node_modules";
      };
      Count = {
        args = ["--filecount"];
        description = "rank directories by number of files instead of size";
      };
      Dirs = {
        args = ["--only-dir"];
        description = "show only directories";
      };
      Errors = {
        args = ["--print-errors"];
        description = "print the paths that could not be read";
      };
      Exclude = {
        args = ["--invert-filter"];
        description = "exclude paths matching a regex, e.g. dustExclude '\\.log$'";
      };
      Files = {
        args = ["--only-file"];
        description = "show only files (finds your largest files)";
      };
      Filter = {
        args = ["--filter"];
        description = "include only paths matching a regex, e.g. dustFilter '\\.mp4$'";
      };
      Gigs = {
        args = ["--output-format" "g"];
        description = "show every size in GiB";
      };
      Json = {
        args = ["--output-json"];
        description = "write the directory tree as JSON to the current directory";
      };
      Links = {
        args = ["--dereference-links"];
        description = "follow symlinks into directories";
      };
      Many = {
        args = ["--number-of-lines" "200"];
        description = "show the 200 largest entries";
      };
      Megs = {
        args = ["--output-format" "m"];
        description = "show every size in MiB";
      };
      Min = {
        args = ["--min-size"];
        description = "hide entries below a minimum size, e.g. dustMin 100M";
      };
      More = {
        args = ["--number-of-lines" "50"];
        description = "show the 50 largest entries";
      };
      Mtime = {
        args = ["--mtime"];
        description = "filter by modified days, e.g. dustMtime +30 for older than 30 days";
      };
      NoBars = {
        args = ["--no-percent-bars"];
        description = "hide percent bars and percentages";
      };
      NoHidden = {
        args = ["--ignore-hidden"];
        description = "skip hidden files";
      };
      Page = {
        args = ["--force-colors" "--number-of-lines" "500"];
        pipe = [["less" "--RAW-CONTROL-CHARS"]];
        description = "browse the 500 largest entries in a pager, keeping colors";
      };
      Paths = {
        args = ["--full-paths"];
        description = "show full paths instead of shortened subdirectories";
      };
      Plain = {
        args = [
          "--no-colors"
          "--no-percent-bars"
          "--no-progress"
          "--number-of-lines"
          "1000000"
        ];
        description = "uncolored list with no bars or progress, for piping";
      };
      Recent = {
        args = ["--mtime" "-7"];
        description = "only files modified in the last 7 days";
      };
      SameFs = {
        args = ["--limit-filesystem"];
        description = "stay on the starting filesystem";
      };
      Shallow = {
        args = ["--depth" "1"];
        description = "show only the top level";
      };
      Si = {
        args = ["--output-format" "si"];
        description = "show sizes in powers of 1000";
      };
      Stale = {
        args = ["--mtime" "+365"];
        description = "only files untouched for over a year";
      };
    };
  };
  eza = mkSource {
    categories = ["files" "scripting"];
    description = "modern ls replacement";
    aliases = let
      cfg = {
        default = {
          args = ["--icons=auto" "--color=auto"];
          description = "with sane defaults";
        };
        plain = {
          args = ["--icons=never" "--color=never" "--oneline"];
          description = "with plain output, one entry per line";
        };
        hidden = {
          args = ["--almost-all"];
          description = "with hidden files";
        };
        info = {
          args = ["--long" "--git"];
          description = "with metadata columns";
        };
        tree = {
          args = ["--tree"];
          description = "with tree output";
        };
        recursive = {
          args = ["--recurse"];
          description = "with recursive output";
        };
        dirs = {
          args = ["--only-dirs"];
          description = "listing only directories";
        };
        #? Must stay last so the caller's next argument becomes its value.
        level = {
          trailing = ["--level"];
          description = "limited to a required depth";
        };
      };

      mkEza = mkLayeredAlias "eza" [cfg.default];

      #? name / namea / namep / namepa / nameap: the view with metadata, hidden files,
      #? plain output, or plain output including hidden files.
      mkViewAlias = name: view: let
        mkPlain = extra: mkEza ([view cfg.plain] ++ extra);
      in {
        ${name} = mkEza [view cfg.info];
        "${name}a" = mkEza [view cfg.hidden];
        "${name}p" = mkPlain [];
        "${name}pa" = mkPlain [cfg.hidden];
        "${name}ap" = mkPlain [cfg.hidden];
      };

      #? Like mkViewAlias, but the caller must supply a depth (e.g. `et 2`).
      mkRecursiveAlias = name: mode:
        mkViewAlias name {
          inherit (mode) args;
          inherit (cfg.level) trailing;
          description = "${mode.description}, ${cfg.level.description}";
        };

      mkSortAlias = name: by:
        mkViewAlias name {
          args = ["--sort=${by}"];
          description = "list sorted by ${by}";
        };
    in
      mergeDisjoint (
        [{ez = mkEza [];}]
        ++ [
          (mkViewAlias "ee" {})
          (mkViewAlias "ed" cfg.dirs)
          (mkViewAlias "ezal" {})
          (mkViewAlias "ezad" cfg.dirs)
          (mkViewAlias "ezat" cfg.tree)
          (mkViewAlias "ezar" cfg.recursive)
          (mkRecursiveAlias "et" cfg.tree)
          (mkRecursiveAlias "er" cfg.recursive)
        ]
        ++ mapAttrsToList mkSortAlias {
          ezan = "name";
          ezaN = "Name";
          ezanDot = ".name";
          ezaNDot = ".Name";
          ezae = "ext";
          ezam = "modified";
          ezac = "created";
          ezaa = "accessed";
          ezaChanged = "changed";
          ezas = "size";
          ezai = "inode";
          ezaType = "type";
          ezaNone = "none";
        }
      );
  };

  fd = mkSource {
    categories = ["files" "scripting"];
    description = "simple, fast find alternative";
    aliases = mkAliasFamily "fd" {
      "0" = {
        args = ["--print0"];
        description = "separate results with NUL bytes";
      };
      d = {
        args = ["--type" "d"];
        description = "find directories only";
      };
      e = {
        args = ["--extension"];
        description = "find files with a caller-specified extension";
      };
      ExecBatch = {
        args = ["--exec-batch"];
        description = "run one command with all results as arguments";
      };
      f = {
        args = ["--type" "f"];
        description = "find regular files only";
      };
      g = {
        args = ["--glob"];
        description = "match with a glob pattern instead of a regex";
      };
      h = {
        args = ["--hidden" "--no-ignore"];
        description = "find files including hidden and ignored paths";
      };
      md = {
        args = ["--max-depth"];
        description = "limit the search depth";
      };
      x = {
        args = ["--exec"];
        description = "run a command once for each result";
      };
    };
  };

  fzf = mkSource {
    categories = ["files" "scripting"];
    description = "command-line fuzzy finder";
    aliases = mkAliasFamily "fzf" {
      "0" = {
        args = ["--read0" "--print0"];
        description = "read and write NUL-separated items";
      };
      "1" = {
        args = ["--select-1" "--exit-0"];
        description = "auto-select a single match and exit when nothing matches";
      };
      e = {
        args = ["--exact"];
        description = "use exact matching instead of fuzzy matching";
      };
      h = {
        args = ["--height" "40%"];
        description = "run inline using 40% of the terminal height";
      };
      m = {
        args = ["--multi"];
        description = "allow selecting multiple items";
      };
      p = {
        args = ["--preview"];
        description = "show a preview command for the highlighted item (caller supplies it)";
      };
      q = {
        args = ["--query"];
        description = "start with a caller-specified query";
      };
      r = {
        args = ["--reverse"];
        description = "show the prompt at the top with results below";
      };
    };
  };

  lsd = mkSource {
    categories = ["files" "scripting"];
    description = "file listing with colours and icons";
    aliases = let
      cfg = {
        default = {
          args = ["--icon=auto" "--color=auto"];
          description = "with sane defaults";
        };
        plain = {
          args = ["--icon=never" "--color=never" "--oneline"];
          description = "with plain output, one entry per line";
        };
        hidden = {
          args = ["--almost-all"];
          description = "with hidden files";
        };
        info = {
          args = ["--long" "--git"];
          description = "with metadata columns";
        };
        tree = {
          args = ["--tree"];
          description = "with tree output";
        };
        recursive = {
          args = ["--recursive"];
          description = "with recursive output";
        };
        dirs = {
          args = ["--directory-only"];
          description = "listing only directories";
        };
        depth = {
          trailing = ["--depth"];
          description = "limited to a required depth";
        };
      };
      mkLsd = mkLayeredAlias "lsd" [cfg.default];
      mkViewAlias = name: view: let
        mkPlain = extra: mkLsd ([view cfg.plain] ++ extra);
      in {
        ${name} = mkLsd [view cfg.info];
        "${name}a" = mkLsd [view cfg.hidden];
        "${name}p" = mkPlain [];
        "${name}pa" = mkPlain [cfg.hidden];
        "${name}ap" = mkPlain [cfg.hidden];
      };
      mkRecursiveAlias = name: mode:
        mkViewAlias name {
          inherit (mode) args;
          inherit (cfg.depth) trailing;
          description = "${mode.description}, ${cfg.depth.description}";
        };
      mkSortAlias = name: by:
        mkViewAlias name {
          args = ["--sort=${by}"];
          description = "list sorted by ${by}";
        };
    in
      mergeDisjoint (
        [
          {
            lsdLong = mkLsd [cfg.info cfg.hidden];
            lsdTree = mkLsd [cfg.tree];
            lsdRecursive = mkLsd [cfg.info cfg.recursive];
          }
        ]
        ++ [
          (mkViewAlias "lsdl" {})
          (mkViewAlias "lsdd" cfg.dirs)
          (mkViewAlias "lsdt" cfg.tree)
          (mkViewAlias "lsdr" cfg.recursive)
          (mkRecursiveAlias "lt" cfg.tree)
          (mkRecursiveAlias "lr" cfg.recursive)
        ]
        ++ mapAttrsToList mkSortAlias {
          lsds = "size";
          lsdm = "time";
          lsdv = "version";
          lsde = "extension";
          lsdGit = "git";
          lsdNone = "none";
        }
      );
  };

  yazi = let
    #? Expanded by the shell at run time, so they follow the current user/host.
    #? `\${` stops Nix from interpolating.
    roots = {
      projects = "\${PROJECTS:-$HOME/Projects}";
      cc = "\${PRJ_CC:-$HOME/Projects/craole-cc}";
      dots = "\${DOTS:-$HOME/.dots}";
      yazi = "\${XDG_CONFIG_HOME:-$HOME/.config}/yazi";
    };
  in
    mkSource {
      categories = ["files" "scripting"];
      description = "terminal file manager";
      aliases = let
        cfg = {
          projects = {
            args = [roots.projects];
            description = "open yazi in the projects root";
          };
          cc = {
            args = [roots.cc];
            description = "open yazi in the craole-cc projects";
          };
          dots = {
            args = [roots.dots];
            description = "open yazi in the dotfiles";
          };
          yazi = {
            args = [roots.yazi];
            description = "open yazi in its own config directory";
          };
          chooserFile = {
            trailing = ["--chooser-file"];
            description = "write the selected file path to a caller-supplied file";
          };
          cwdFile = {
            trailing = ["--cwd-file"];
            description = "write the final working directory to a caller-supplied file";
          };
          select = {
            trailing = ["--select"];
            description = "select a caller-supplied file on startup";
          };
        };
        mkYazi = mkLayeredAlias "yazi" [];
        mkRootAliases = names: root:
          mergeDisjoint (map (name: {${name} = mkYazi [root];}) names);
      in
        mergeDisjoint [
          (mkRootAliases ["f" "y" "yz"] {})
          (mkRootAliases ["yp" "yaziProjects"] cfg.projects)
          (mkRootAliases ["yc" "yaziCC"] cfg.cc)
          (mkRootAliases ["yd" "yaziDots"] cfg.dots)
          (mkRootAliases ["yy" "yaziYazi"] cfg.yazi)
          (mkAliasFamily "yazi" {
            ChooserFile = {
              inherit (cfg.chooserFile) description;
              args = cfg.chooserFile.trailing;
            };
            CwdFile = {
              inherit (cfg.cwdFile) description;
              args = cfg.cwdFile.trailing;
            };
            Select = {
              inherit (cfg.select) description;
              args = cfg.select.trailing;
            };
          })
        ];
    };
}
