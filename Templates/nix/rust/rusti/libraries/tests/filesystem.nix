{
  lib,
  assertMsg,
}: let
  inherit
    (lib.filesystem)
    foldersToExclude
    isNixFile
    isIncludedDir
    collectFromDir
    collectPaths
    ;
  inherit
    (lib.filesystem)
    importPaths
    importAttrs
    importLibs
    normalizeInput
    inferNamespace
    ;

  inherit (lib.lists) isList;

  fixture = ./fixtures/filesystem;
  plainDir = fixture + "/plain";
  nestedDir = fixture + "/nested";
  attrsDir = fixture + "/attrs";
  libsDir = fixture + "/libs";
in {
  foldersToExclude =
    assertMsg
    (builtins.elem "tmp" foldersToExclude
      && builtins.elem "review" foldersToExclude)
    "foldersToExclude exposes excluded directory names";

  isNixFile =
    assertMsg
    (isNixFile "foo.nix" "regular"
      && !(isNixFile "default.nix" "regular")
      && !(isNixFile "foo.txt" "regular")
      && !(isNixFile "foo.nix" "directory"))
    "isNixFile detects only regular non-default .nix files";

  isIncludedDir =
    assertMsg
    (isIncludedDir "modules" "directory"
      && !(isIncludedDir "tmp" "directory")
      && !(isIncludedDir "foo.nix" "regular"))
    "isIncludedDir accepts real directories except excluded ones";

  normalizeInputPath =
    assertMsg
    ((normalizeInput {} plainDir)
      == {
        recurse = false;
        namespace = null;
        args = {};
        priority = [];
        ignore = [];
        path = plainDir;
      })
    "normalizeInput normalizes a path input";

  normalizeInputList =
    assertMsg
    ((normalizeInput {} [plainDir])
      == {
        recurse = false;
        namespace = null;
        args = {};
        priority = [];
        ignore = [];
        path = [plainDir];
      })
    "normalizeInput normalizes a list input";

  normalizeInputAttrs =
    assertMsg
    ((normalizeInput {} {
        path = libsDir;
        recurse = true;
        namespace = "demo";
        args = {value = 7;};
        priority = ["base.nix"];
        ignore = ["tests"];
      })
      == {
        path = libsDir;
        recurse = true;
        namespace = "demo";
        args = {value = 7;};
        priority = ["base.nix"];
        ignore = ["tests"];
      })
    "normalizeInput preserves explicit attribute input";

  inferNamespaceFile =
    assertMsg
    (inferNamespace ./fixtures/filesystem/libs/demo.nix == "demo")
    "inferNamespace strips the .nix suffix from file names";

  inferNamespaceDir =
    assertMsg
    (inferNamespace ./fixtures/filesystem/libs == "libs")
    "inferNamespace uses the basename for directories";

  collectFromDirPlain =
    assertMsg
    ((collectFromDir {
        path = plainDir;
        recurse = false;
        ignore = [];
      })
      == [
        (plainDir + "/a.nix")
        (plainDir + "/z.nix")
      ])
    "collectFromDir collects plain nix files and skips default.nix";

  collectFromDirNestedNoRecurse =
    assertMsg
    ((collectFromDir {
        path = nestedDir;
        recurse = false;
        ignore = [];
      })
      == [
        (nestedDir + "/root.nix")
        (nestedDir + "/has-default")
      ])
    "collectFromDir includes subdirectories with default.nix without recursion";

  collectFromDirNestedRecurse =
    assertMsg
    ((collectFromDir {
        path = nestedDir;
        recurse = true;
        ignore = [];
      })
      == [
        (nestedDir + "/root.nix")
        (nestedDir + "/deep/leaf.nix")
        (nestedDir + "/has-default")
      ])
    "collectFromDir recurses into included subdirectories";

  collectFromDirIgnore =
    assertMsg
    ((collectFromDir {
        path = nestedDir;
        recurse = true;
        ignore = ["deep" "has-default"];
      })
      == [
        (nestedDir + "/root.nix")
      ])
    "collectFromDir respects ignore names";

  collectPathsReturnsList =
    assertMsg
    (isList (collectPaths {
      path = fixture;
      recurse = true;
      ignore = [];
    }))
    "collectPaths returns a list";

  collectPathsDir =
    assertMsg
    ((collectPaths {
        path = plainDir;
        recurse = false;
        ignore = [];
      })
      == [
        (plainDir + "/a.nix")
        (plainDir + "/z.nix")
      ])
    "collectPaths handles a directory input";

  collectPathsFile =
    assertMsg
    ((collectPaths {
        path = plainDir + "/a.nix";
        recurse = false;
        ignore = [];
      })
      == [
        (plainDir + "/a.nix")
      ])
    "collectPaths handles a single file input";

  collectPathsList =
    assertMsg
    ((collectPaths {
        path = [
          (plainDir + "/a.nix")
          (plainDir + "/z.nix")
        ];
        recurse = false;
        ignore = [];
      })
      == [
        (plainDir + "/a.nix")
        (plainDir + "/z.nix")
      ])
    "collectPaths handles a list of paths";

  collectPathsIgnore =
    assertMsg
    ((collectPaths {
        path = nestedDir;
        recurse = true;
        ignore = ["deep" "has-default"];
      })
      == [
        (nestedDir + "/root.nix")
      ])
    "collectPaths respects ignore names";

  importPaths =
    assertMsg
    ((importPaths {
        path = nestedDir;
        recurse = true;
        ignore = [];
      })
      == [
        (nestedDir + "/root.nix")
        (nestedDir + "/deep/leaf.nix")
        (nestedDir + "/has-default")
      ])
    "importPaths delegates to collectPaths";

  importPathsIgnore =
    assertMsg
    ((importPaths {
        path = nestedDir;
        recurse = true;
        ignore = ["deep" "has-default"];
      })
      == [
        (nestedDir + "/root.nix")
      ])
    "importPaths supports ignore";

  importsAlias =
    assertMsg
    ((lib.filesystem.imports {
        path = nestedDir;
        recurse = false;
        ignore = [];
      })
      == (importPaths {
        path = nestedDir;
        recurse = false;
        ignore = [];
      }))
    "imports is an alias of importPaths";

  importAttrs =
    assertMsg
    ((importAttrs {
        path = attrsDir;
        args = {value = 9;};
        ignore = [];
      })
      == {
        __meta = {
          names = ["alpha" "beta"];
          values = [9 "ok"];
          all = {
            alpha = 9;
            beta = "ok";
          };
        };
        alpha = 9;
        beta = "ok";
      })
    "importAttrs imports attrsets with filtered args and metadata";

  importAttrsIgnore =
    assertMsg
    ((importAttrs {
        path = attrsDir;
        args = {value = 9;};
        ignore = ["beta.nix"];
      })
      == {
        __meta = {
          names = ["alpha"];
          values = [9];
          all = {
            alpha = 9;
          };
        };
        alpha = 9;
      })
    "importAttrs supports ignore";

  importLibs =
    assertMsg
    ((importLibs libsDir)
      == {
        libs = {
          base = 1;
          derived = 2;
        };
        __meta.libs = {
          namespace = "libs";
          names = ["base" "derived"];
          values = [1 2];
          all = {
            base = 1;
            derived = 2;
          };
          paths = [
            (libsDir + "/base.nix")
            (libsDir + "/derived.nix")
          ];
        };
      })
    "importLibs infers namespace and assembles staged library fragments";

  importLibsExplicit =
    assertMsg
    ((importLibs {
        path = libsDir;
        namespace = "custom";
        priority = ["base.nix" "derived.nix"];
        ignore = [];
      })
      == {
        custom = {
          base = 1;
          derived = 2;
        };
        __meta.custom = {
          namespace = "custom";
          names = ["base" "derived"];
          values = [1 2];
          all = {
            base = 1;
            derived = 2;
          };
          paths = [
            (libsDir + "/base.nix")
            (libsDir + "/derived.nix")
          ];
        };
      })
    "importLibs supports explicit namespace and priority";

  importLibsIgnore =
    assertMsg
    ((importLibs {
        path = libsDir;
        namespace = "custom";
        ignore = ["derived.nix"];
      })
      == {
        custom = {
          base = 1;
        };
        __meta.custom = {
          namespace = "custom";
          names = ["base"];
          values = [1];
          all = {
            base = 1;
          };
          paths = [
            (libsDir + "/base.nix")
          ];
        };
      })
    "importLibs supports ignore";
}
