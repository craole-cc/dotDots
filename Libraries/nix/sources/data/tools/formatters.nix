{
  mkAliasFamily,
  mkSource,
  ...
}: {
  alejandra = mkSource {
    categories = ["formatters" "scripting"];
    description = "opinionated Nix formatter";
    aliases = mkAliasFamily "alejandra" {
      aliasPrefix = "alj";
      Check = {
        args = ["--check"];
        description = "check formatting without changing files";
      };
      Quiet = {
        args = ["--quiet"];
        description = "format files without printing progress output";
      };
      Here = {
        args = ["."];
        description = "format every Nix file under the current directory";
      };
    };
  };

  biome = mkSource {
    categories = ["formatters" "scripting"];
    description = "fast formatter and linter for JS, TS, JSON, and CSS";
    aliases = mkAliasFamily "biome" {
      Check = {
        args = ["check"];
        description = "run the formatter, linter, and import sorting checks";
      };
      Fix = {
        args = ["check" "--write"];
        description = "run all checks and apply safe fixes";
      };
      CI = {
        args = ["ci"];
        description = "run read-only checks suited to CI";
      };
      Format = {
        args = ["format" "--write"];
        description = "format files in place";
      };
      Lint = {
        args = ["lint"];
        description = "lint files without changing them";
      };
    };
  };

  dprint = mkSource {
    categories = ["formatters" "scripting"];
    description = "pluggable multi-language code formatter";
    aliases = mkAliasFamily "dprint" {
      Check = {
        args = ["check"];
        description = "check formatting without changing files";
      };
      Fmt = {
        args = ["fmt"];
        description = "format files in place";
      };
      Init = {
        args = ["init"];
        description = "create a dprint configuration file";
      };
    };
  };

  treefmt = mkSource {
    categories = ["formatters" "scripting"];
    description = "multi-language code formatter";
    input = "treefmt";
    target = "treefmt";
    exe = "treefmt";
  };
}
