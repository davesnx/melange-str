# `melange-str`

This is a complete implementation of OCaml's `Str` module for Melange, using JavaScript's `RegExp` as the backend.

### Installation

```sh
opam install melange-str
```

Then add `melange-str` to the `libraries` field in your `dune` file:

```dune
(library
 (name my_lib)
 (modes melange)
 (libraries melange-str)
 (preprocess (pps melange.ppx)))
```

### Basic matching

```ocaml
let r = Str.regexp {|hello \([A-Za-z]+\)|}
let matched = Str.string_match r "hello world" 0
(* true *)

let group = Str.matched_group 1 "hello world"
(* "world" *)
```

### Search and replace

```ocaml
let r = Str.regexp {|foo|}
Str.global_replace r "bar" "foo foo foo"
(* "bar bar bar" *)

(* With capture groups *)
let r = Str.regexp {|\([a-z]+\) \([a-z]+\)|}
Str.global_replace r {|\2 \1|} "hello world"
(* "world hello" *)
```

### Split

```ocaml
(* Split on whitespace *)
let r = Str.regexp {| +|}
Str.split r "hello   world   test"
(* ["hello"; "world"; "test"] *)

(* Split with delimiters *)
let r = Str.regexp {|[,;]|}
Str.full_split r "a,b;c"
(* [Text "a"; Delim ","; Text "b"; Delim ";"; Text "c"] *)
```

### Advanced features

```ocaml
(* Case-insensitive matching *)
let r = Str.regexp_case_fold {|hello|}
Str.string_match r "HELLO" 0  (* true *)

(* Search backward *)
let r = Str.regexp {|[0-9]+|}
Str.search_backward r "abc 123 def 456 ghi" 10
(* 4 (position of "123") *)

(* Substitute with function *)
let r = Str.regexp {|[0-9]+|}
Str.global_substitute r
  (fun s ->
    let n = int_of_string (Str.matched_string s) in
    string_of_int (n * 2))
  "a 10 b 20 c"
(* "a 20 b 40 c" *)
```

### Universal code (Melange + Native)

If you have code that uses `Str` and needs to compile for both Melange (JavaScript) and native OCaml, you can use dune's `copy_files` to share source files between both targets. The Melange side depends on `melange-str` while the native side depends on OCaml's `str`.

We recommend placing shared source files inside the native folder. The native library uses them directly, and the Melange library copies them in via `copy_files`. This way the native side is the "source of truth" and doesn't need any extra dune stanzas.

```
server/
  shared/
    input.ml        <- your code that uses Str
  dune              <- native library
client/
  dune              <- melange library (copies from server/shared)
```

**`server/shared/input.ml`**:
```ocaml
let parse_csv line =
  let r = Str.regexp {|,|} in
  Str.split r line

let replace_dates text =
  let r = Str.regexp {|\([0-9]+\)/\([0-9]+\)/\([0-9]+\)|} in
  Str.global_replace r {|\3-\2-\1|} text
```

**`server/dune`** (Native):
```dune
(library
 (name my_parser_native)
 (modes native)
 (libraries str)
 (wrapped false))
```

**`client/dune`** (Melange):
```dune
(library
 (name my_parser_js)
 (modes melange)
 (libraries melange-str)
 (wrapped false)
 (preprocess (pps melange.ppx)))

(copy_files#
 (source_only)
 (mode fallback)
 (files "../server/shared/*.ml"))
```

Both libraries expose the same modules, so the rest of your code can depend on `my_parser_js` or `my_parser_native` depending on the target. The `mode fallback` option lets you override a shared file in `client/` if you need Melange-specific behavior.

For more details on organising universal code, see [How to organise universal code](https://ml-in-barcelona.github.io/server-reason-react/server-reason-react/how-to-organise-universal-code.html).

### Known Limitations

1. **Partial match**: Simplified implementation (may not catch all prefix cases)
2. **Nested group positions**: Approximate due to JavaScript RegExp limitations
3. **Some PCRE features**: Not available (e.g., named captures in OCaml Str syntax)
