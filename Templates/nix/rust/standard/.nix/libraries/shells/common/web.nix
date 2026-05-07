{lib, ...}: let
  inherit (lib.packages) mkBins mkBin;
  inherit (lib.shells) setSource;
in {
  mkWeb = pkgs: let
    templates = {
      deno = {
        source = setSource ["web" "deno.jsonc"];
        target = "deno.jsonc";
      };
      prettier = {
        source = setSource ["web" "prettierrc"];
        target = [".prettierrc" "prettier.config.json"];
      };
      trunk = {
        source = setSource ["web" "trunk.toml"];
        target = [
          ".trunk.toml"
          "Trunk.toml"
          ".trunk.yaml"
          "Trunk.yaml"
          ".trunk.json"
          "Trunk.json"
        ];
      };
    };

    packages = with pkgs; {
      inherit deno pnpm prettierd;
    };

    bin = {
      packages = mkBins packages;
      scripts = mkBins scripts;
      all = bin.packages // bin.scripts;
    };

    scripts = with packages;
      mkBin {
        inherit pkgs;
        prefix = "pnpm";
        set = {
          i = {command = "${pnpm} install";};
          a = {script = ''${pnpm} add "$@"'';};
          ad = {script = ''${pnpm} add --save-dev "$@"'';};
        };
      }
      // mkBin {
        inherit pkgs;
        prefix = "deno";
        set = {
          dev = {script = ''${deno} task dev "$@"'';};
          run = {script = ''${deno} run "$@"'';};
          lint = {command = "${deno} lint";};
          fmt = {command = "${deno} fmt";};
          test = {script = ''${deno} test "$@"'';};
          check = {script = ''${deno} check "$@"'';};
        };
      };
  in {inherit templates scripts packages;};
}
