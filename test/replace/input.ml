let print_string label s = Printf.printf "%s: %s\n" label s

let () =
  let r = Str.regexp {|foo|} in
  print_string "all replaced" (Str.global_replace r "bar" "foo foo foo");

  let r = Str.regexp {|\([a-z]+\) \([a-z]+\)|} in
  print_string "swap" (Str.global_replace r {|\2 \1|} "hello world");

  let r = Str.regexp {|[a-z]+|} in
  print_string "bracket" (Str.global_replace r {|[\0]|} "hello world");

  let r = Str.regexp {|\([a-z]\)\([a-z]\)|} in
  print_string "swapped" (Str.global_replace r {|\2\1|} "abcd");

  let r = Str.regexp {|foo|} in
  print_string "first only" (Str.replace_first r "bar" "foo foo foo");

  let r = Str.regexp {|\([a-z]+\) \([a-z]+\)|} in
  print_string "first swap"
    (Str.replace_first r {|\2 \1|} "hello world foo bar");

  let r = Str.regexp {|xyz|} in
  print_string "unchanged" (Str.global_replace r "abc" "hello world");

  let r = Str.regexp {|xyz|} in
  print_string "unchanged" (Str.replace_first r "abc" "hello world");

  let r = Str.regexp {|[0-9]+|} in
  let result =
    Str.global_substitute r
      (fun s ->
        let n = int_of_string (Str.matched_string s) in
        string_of_int (n * 2))
      "a 10 b 20 c 30"
  in
  print_string "doubled" result;

  let r = Str.regexp {|[0-9]+|} in
  let result =
    Str.substitute_first r
      (fun s ->
        let n = int_of_string (Str.matched_string s) in
        string_of_int (n * 2))
      "a 10 b 20 c 30"
  in
  print_string "first doubled" result;

  let r = Str.regexp {|\([a-z]+\)=\([0-9]+\)|} in
  let result =
    Str.global_substitute r
      (fun s ->
        let key = Str.matched_group 1 s in
        let value = Str.matched_group 2 s in
        Printf.sprintf "%s:%s" (String.uppercase_ascii key) value)
      "x=1 y=2 z=3"
  in
  print_string "transformed" result;

  let r = Str.regexp {|\([a-z]+\) \([0-9]+\)|} in
  let _ = Str.string_match r "hello 123" 0 in
  print_string "template" (Str.replace_matched {|\2-\1|} "hello 123");

  let r = Str.regexp {|[a-z]+|} in
  let _ = Str.string_match r "hello" 0 in
  print_string "whole match" (Str.replace_matched {|[\0]|} "hello");

  let r = Str.regexp {|x*|} in
  print_string "empty pattern on 'abc'" (Str.global_replace r "-" "abc")
