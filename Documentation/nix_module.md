# Nix Module Template

## File Structure

````nix
{ _,
  __moduleDir,
  __moduleName,
 ...
}: let
  inherit (_.some.namespace) foo bar;
  inherit (_.other.namespace) baz;

  /**
    <One-line summary of what the function does.>

    <Optional second paragraph for edge cases, defaults, or guards.>

    # Type
    ```nix
    fnOne :: {
      argA :: type,
      argB :: type,      # optional, default <value>
    } -> ReturnType
    ```

    # Examples
    ```nix
    fnOne {
      argA = <value>;
      argB = <value>;
    }
    # => <result>

    # <Description of the boundary/edge case being shown>
    fnOne {
      argA = <edge value>;
    }
    # => <result>
    ```
  */
  fnOne = {
    argA,
    argB ? <default>,
  }: <body>;

in
  _.meta.mkModuleExports {
    directory = __moduleDir;
    filename = __moduleName; #? Using this creates namespaced aliases as well eg. fnOneNamespace
    doc = ''
      <Module title> (Layer N).

      <2–4 sentence description of what this module provides.>

      Depends on: <dependencies>
'';

    functions = {
      inherit fnOne;
      customFnOne = fnOne;
    };

    tests = runTests {
      fnOne = {
        <descriptiveCamelCaseName> = mkTest {
          desired = <expected>;
          command = ''fnOne { argA = <value>; }'';
          outcome = fnOne {argA = <value>;};
        };
        <edgeCaseName> = mkTest {
          desired = <expected>;
          command = ''fnOne { argA = <edge value>; }'';
          outcome = fnOne {argA = <edge value>;};
        };
      };
    };
  }
````

---

## Ordering

1. `__docs`
2. `__exports`
3. `__imports`
4. functions (each preceded by its `/** */` docstring)
5. `in` clause - `__exports.internal // { __rootAliases, __docs, __tests }`

---

## `__exports` Convention

Internal exports use bare `inherit` - names are used as-is within the module
tree. External exports **must be namespaced** to avoid collisions at the root
level.

```nix
__exports = {
  internal = {
    inherit
      toPath
      toValue
      toName
      ;
  };
  external = {
    #~@ prefixed to avoid root-level collisions
    toApplicationPath  = toPath;
    toApplicationValue = toValue;
    toApplicationName  = toName;
  };
};
```

The naming pattern for external keys is `<domain><FunctionName>` - e.g.
`toApplication*`, `mkUser*`, `hasConfig*`. Bare `inherit` in `external` is only
appropriate when the name is already globally unambiguous.

## Docstring Format (`/** */`)

- Summary sentence(s) first - plain prose, no heading
- Edge cases / defaults / guards in a second paragraph if needed
- `# Type` block - pseudo-signature using `::`, named record args, `|` for
  unions, `?` suffix or inline comment for optionals
- `# Examples` block - at least two: one typical case, one boundary/edge case
  with a comment explaining what it demonstrates
- Indent body content by 2 spaces inside the `/** */`
- Fenced code blocks are flush with the left margin of the docstring

---

## Tests (`__tests`)

Tests live in the `in` clause under `__tests = runTests { ... }`.

```nix
__tests = runTests {
  fnOne = {
    # name describes what is being asserted, not what the function is
    allowsValidValue = mkTest {
      desired = true;
      command = ''fnOne { argA = "valid"; }'';    #? string shown in failure output
      outcome = fnOne {argA = "valid";};          #? actual evaluation
    };
    rejectsInvalidValue = mkTest {
      desired = false;
      command = ''fnOne { argA = "bad"; }'';
      outcome = fnOne {argA = "bad";};
    };
  };
};
```

**Test naming conventions** - names should read as assertions:

- `allowsX` / `deniesX` - for boolean predicates
- `returnsX` / `exportsX` - for value/shape checks
- `resolvesX` - for lookup / alias resolution
- `caseSensitiveWithExact` / `caseInsensitiveByDefault` - for case behaviour

Cover at minimum: the happy path, the rejection path, and any case-sensitivity
or default-value behaviour.

---

## Inline Comments

| Sigil | Use                                      |
| ----- | ---------------------------------------- |
| `#~@` | groups, lists, collections               |
| `#>`  | runners, verbs, active steps             |
| `#?`  | checks, guards, questions, preconditions |

### Section Headings (for long files)

```nix
#╔═══════════════════════════════════════════════════════════╗
#║ Heading Text                                              ║
#╚═══════════════════════════════════════════════════════════╝
```

---

## Type Conventions

| Pattern                  | Meaning                             |
| ------------------------ | ----------------------------------- |
| `string` `bool` `int`    | primitives                          |
| `AttrSet`                | untyped attribute set               |
| `{ ${key} :: AttrSet }`  | attrset with dynamic keys           |
| `A \| B`                 | union / nullable (`string \| null`) |
| `# optional, default ""` | optional record field with default  |
| `-> X \| {}`             | may return empty attrset            |

---

## `__docs` Format

```md
<Title> (Layer N).

<What this module provides - 2–4 sentences.>
<Mention any notable behaviour shared across functions.>

Depends on: <comma-separated list>
```

Surfaces as a readable string in `nix repl` and is exported via
`inherit __docs;`.
