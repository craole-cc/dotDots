{
  context,
  mkEnable,
  requires,
  ...
}: let
  lang = "go";
  condition = requires lang;
  enable = condition;
  options.${lang}.enable = mkEnable {inherit context condition;};

  defaultFormatter = "golang.Go";
  extensions = [defaultFormatter];
  settings = {
    "[${lang}]".editor = {
      inherit defaultFormatter;
      insertSpaces = false;
      codeActionsOnSave.source.organizeImports = "explicit";
    };

    editor.tokenColorCustomizations.textMateRules = [
      {
        scope = [
          "source.${lang} keyword.package.${lang}"
          "source.${lang} keyword.import.${lang}"
          "source.${lang} keyword.function.${lang}"
          "source.${lang} keyword.type.${lang}"
          "source.${lang} keyword.struct.${lang}"
          "source.${lang} keyword.interface.${lang}"
          "source.${lang} keyword.const.${lang}"
          "source.${lang} keyword.var.${lang}"
          "source.${lang} keyword.map.${lang}"
          "source.${lang} keyword.channel.${lang}"
          "source.${lang} keyword.control.${lang}"
        ];
        settings.fontStyle = "italic";
      }
    ];
  };
in {inherit enable extensions options settings;}
