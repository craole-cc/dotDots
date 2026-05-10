{lib, ...}: let
  inherit (lib.packages) mkBins mkBin;
  templates = lib.templates.base;
in {
  mkWeb = pkgs: let
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
