{
  mkSource,
  mkAlias,
  mkAliasFamily,
  mergeDisjoint,
  ...
}: {
  llmhop = mkSource {
    categories = ["scripting" "ai"];
    description = "Language model request router";
    input = "llmhop";
    aliases = let
      cmd = "llmhop";
      mk = alias: mkAlias cmd alias;

      variants = {
        Check = {
          args = ["-check"];
          description = "validate config.json in this directory and exit";
        };
        Config = {
          args = ["-config"];
          description = "serve with a specific config, e.g. llmhop-config ./hop.json";
        };
        CheckConfig = {
          args = ["-check" "-config"];
          description = "validate a specific config and exit, e.g. llmhop-validate ./hop.json";
        };
      };
    in
      mergeDisjoint [
        {
          llmhop-check = mk variants.Check;
          llmhop-config = mk variants.Config;
          llmhop-validate = mk variants.CheckConfig;
        }
        (mkAliasFamily cmd variants)
      ];
  };

  ollama = mkSource {
    categories = ["scripting" "ai"];
    description = "Local language model inference";
    aliases = let
      cmd = "ollama";
      mk = alias: mkAlias cmd alias;

      variants = {
        Serve = {
          args = ["serve"];
          description = "start the ollama server";
        };
        List = {
          args = ["list"];
          description = "list installed models";
        };
        Find = {
          args = ["list"];
          pipe = [["rg" "-i"]];
          description = "search installed models, e.g. ollama-find llama";
        };
        Ps = {
          args = ["ps"];
          description = "list running models";
        };
        Run = {
          args = ["run"];
          description = "run a model, e.g. ollama-run llama3";
        };
        Stop = {
          args = ["stop"];
          description = "stop a running model";
        };
        Pull = {
          args = ["pull"];
          description = "pull a model from the registry";
        };
        Push = {
          args = ["push"];
          description = "push a model to the registry";
        };
        Show = {
          args = ["show"];
          description = "show information for a model";
        };
        Create = {
          args = ["create"];
          description = "create a model from a Modelfile";
        };
        Copy = {
          args = ["cp"];
          description = "copy a model";
        };
        Remove = {
          args = ["rm"];
          description = "remove a model";
        };
        Launch = {
          args = ["launch"];
          description = "launch the ollama menu or an integration";
        };
        Signin = {
          args = ["signin"];
          description = "sign in to ollama.com";
        };
        Signout = {
          args = ["signout"];
          description = "sign out of ollama.com";
        };
      };
    in
      mergeDisjoint [
        {
          ollama-ls = mk variants.List;
          ollama-find = mk variants.Find;
          ollama-ps = mk variants.Ps;
          ollama-run = mk variants.Run;
          ollama-pull = mk variants.Pull;
          ollama-stop = mk variants.Stop;
          ollama-show = mk variants.Show;
          ollama-rm = mk variants.Remove;
        }
        (mkAliasFamily cmd variants)
      ];
  };

  ollama-cpu = mkSource {
    categories = ["scripting" "ai"];
    description = "Local language model inference on the CPU";
  };
}
