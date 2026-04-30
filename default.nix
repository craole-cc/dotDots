{
  lib ? null,
  flake ? null,
  paths ? {
    src = ./.;
    libraries = ./Libraries/nix;
  },
  names ? {
    top = "_";
    lib = "lix";
  },
}: let
  libraries = import paths.libraries {
    inherit paths flake names lib;
  };
  inherit (libraries) lix;
  inherit (lix.filesystem.tree) mkTree mkLangGroup;
  inherit (lix.schema._) mkSchema;
  tree = mkTree {
    stems = {
      api = let
        base = [
          "API"
          "nix"
        ];
      in
        mkLangGroup ["API"] {
          nix = "nix";
          rs = "rust";
        }
        // {
          hosts = base ++ ["hosts"];
          users = base ++ ["users"];
        };

      cfg = {
        default = ["Configuration"];
      };

      env = {
        default = ["Environment"];
      };

      kit = let
        base = [
          "Templates"
          "nix"
        ];
      in
        mkLangGroup ["Templates"] {
          nix = "nix";
          rs = "rust";
          sh = "shellscript";
        }
        // {
          common = base ++ ["common"];
          dev = base ++ ["dev"];
          media = base ++ ["media"];
          full = base ++ ["full"];
        };

      lib = mkLangGroup ["Libraries"] {
        bash = "bash";
        nix = "nix";
        nu = "nushell";
        sh = "shellscript";
        pwsh = "powershell";
        py = "python";
        rs = "rust";
      };

      mod = let
        base = [
          "Modules"
          "nix"
        ];
      in
        mkLangGroup ["Modules"] {
          nix = "nix";
          rs = "rust";
        }
        // {
          global = base ++ ["global"];
          core = base ++ ["core"];
          home = base ++ ["home"];
        };

      pkg = let
        base = [
          "Packages"
          "nix"
        ];
      in
        mkLangGroup ["Packages"] {
          nix = "nix";
          rs = "rust";
        }
        // {
          global = base ++ ["global"];
          core = base ++ ["core"];
          home = base ++ ["home"];
          overlays = base ++ ["overlays"];
          plugins = base ++ ["plugins"];
        };

      sec = let
        base = ["Private"];
      in {
        default = base;
        age = base ++ ["secrets.nix"];
        vpn = base ++ ["vpn.age"];
      };

      res = let
        images = [
          "Assets"
          "Images"
        ];
      in {
        default = ["Assets"];
        inherit images;
        fonts = [
          "Assets"
          "Fonts"
        ];
        icons = [
          "Assets"
          "Icons"
        ];
        ascii = images ++ ["ascii"];
        logo = images ++ ["logo"];
        wallpapers = images ++ ["wallpaper"];
      };
    };
  };
  schema = mkSchema {inherit tree;};
  inherit (schema) hosts users;
  # pkgs = lix.
in {
  inherit (names) top;
  inherit
    lix
    tree
    schema
    hosts
    users
    ;
}
