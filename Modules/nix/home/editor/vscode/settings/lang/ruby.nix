{
  context,
  mkEnable,
  requires,
  ...
}: let
  lang = "ruby";
  condition = requires lang;
  enable = condition;
  options.${lang}.enable = mkEnable {inherit context condition;};

  defaultFormatter = "LoranKloeze.ruby-rubocop-revived";
  extensions = [defaultFormatter];
  settings = {
    "[${lang}]".editor = {inherit defaultFormatter;};
    rubyLsp.enableExperimentalFeatures = true;

    #~@ Semantic  Colour and style for TextMate scopes.
    editor.tokenColorCustomizations.textMateRules = [
      {
        scope = [
          "keyword.control.${lang}"
          "keyword.control.module.${lang}"
          "keyword.control.class.${lang}"
          "keyword.control.def.${lang}"
        ];
        settings.fontStyle = "italic";
      }
    ];
  };
in {inherit enable extensions options settings;}
