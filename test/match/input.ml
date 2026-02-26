let print_bool label b = Printf.printf "%s: %b\n" label b
let print_string label s = Printf.printf "%s: %s\n" label s

let () =
  let r = Str.regexp {|hello|} in
  print_bool "match 'hello' at 0" (Str.string_match r "hello world" 0);
  print_bool "match 'hello' at 1" (Str.string_match r "hello world" 1);
  print_bool "match 'hello' in 'say hello'" (Str.string_match r "say hello" 0);

  let r = Str.regexp {|world|} in
  print_bool "match 'world' at 0" (Str.string_match r "hello world" 0);
  print_bool "match 'world' at 6" (Str.string_match r "hello world" 6);

  let r = Str.regexp_case_fold {|hello|} in
  print_bool "HELLO" (Str.string_match r "HELLO" 0);
  print_bool "Hello" (Str.string_match r "Hello" 0);
  print_bool "hElLo" (Str.string_match r "hElLo" 0);

  let r = Str.regexp_case_fold {|[a-z]+|} in
  print_bool "case fold [a-z]+ on 'ABC'" (Str.string_match r "ABC" 0);

  let r = Str.regexp_string "a.b+c" in
  print_bool "literal 'a.b+c'" (Str.string_match r "a.b+c" 0);
  print_bool "not pattern 'aXbbc'" (Str.string_match r "aXbbc" 0);

  let r = Str.regexp_string_case_fold "Hello" in
  print_bool "matches 'hello'" (Str.string_match r "hello" 0);
  print_bool "matches 'HELLO'" (Str.string_match r "HELLO" 0);

  let q = Str.quote "a.b*c+d?" in
  let r = Str.regexp q in
  print_bool "quoted literal" (Str.string_match r "a.b*c+d?" 0);
  print_bool "quoted no wildcard" (Str.string_match r "aXbXcXdX" 0);

  let r = Str.regexp {|a.c|} in
  print_bool "a.c -> 'abc'" (Str.string_match r "abc" 0);
  print_bool "a.c -> 'a1c'" (Str.string_match r "a1c" 0);
  print_bool "a.c -> 'ac'" (Str.string_match r "ac" 0);

  let r = Str.regexp {|[0-9]+|} in
  print_bool "[0-9]+ -> '123'" (Str.string_match r "123" 0);
  print_bool "[0-9]+ -> 'abc'" (Str.string_match r "abc" 0);

  let r = Str.regexp {|[^0-9]+|} in
  print_bool "[^0-9]+ -> 'abc'" (Str.string_match r "abc" 0);
  print_bool "[^0-9]+ -> '123'" (Str.string_match r "123" 0);

  let r = Str.regexp {|[a-zA-Z_][a-zA-Z0-9_]*|} in
  print_bool "identifier -> 'foo_bar'" (Str.string_match r "foo_bar" 0);
  print_bool "identifier -> '_x1'" (Str.string_match r "_x1" 0);
  print_bool "identifier -> '1abc'" (Str.string_match r "1abc" 0);

  let r = Str.regexp {|ab*c|} in
  print_bool "ab*c -> 'ac'" (Str.string_match r "ac" 0);
  print_bool "ab*c -> 'abc'" (Str.string_match r "abc" 0);
  print_bool "ab*c -> 'abbc'" (Str.string_match r "abbc" 0);

  let r = Str.regexp {|ab+c|} in
  print_bool "ab+c -> 'ac'" (Str.string_match r "ac" 0);
  print_bool "ab+c -> 'abc'" (Str.string_match r "abc" 0);
  print_bool "ab+c -> 'abbc'" (Str.string_match r "abbc" 0);

  let r = Str.regexp {|ab?c|} in
  print_bool "ab?c -> 'ac'" (Str.string_match r "ac" 0);
  print_bool "ab?c -> 'abc'" (Str.string_match r "abc" 0);
  print_bool "ab?c -> 'abbc'" (Str.string_match r "abbc" 0);

  let r = Str.regexp {|foo\|bar|} in
  print_bool "foo|bar -> 'foo'" (Str.string_match r "foo" 0);
  print_bool "foo|bar -> 'bar'" (Str.string_match r "bar" 0);
  print_bool "foo|bar -> 'baz'" (Str.string_match r "baz" 0);

  let r = Str.regexp {|a\|b\|c|} in
  print_bool "a|b|c -> 'a'" (Str.string_match r "a" 0);
  print_bool "a|b|c -> 'b'" (Str.string_match r "b" 0);
  print_bool "a|b|c -> 'c'" (Str.string_match r "c" 0);
  print_bool "a|b|c -> 'd'" (Str.string_match r "d" 0);

  let r = Str.regexp {|^hello|} in
  print_bool "^hello at start" (Str.string_match r "hello world" 0);
  print_bool "^hello not at start" (Str.string_match r "say hello" 0);

  let r = Str.regexp {|a\.b|} in
  print_bool "a\\.b -> 'a.b'" (Str.string_match r "a.b" 0);
  print_bool "a\\.b -> 'axb'" (Str.string_match r "axb" 0);

  let r = Str.regexp {|a\\b|} in
  print_bool "a\\\\b -> 'a\\b'" (Str.string_match r "a\\b" 0);

  let r = Str.regexp {|\bhello\b|} in
  print_bool "\\b at word boundary" (Str.string_match r "say hello world" 4);
  print_bool "\\b not at boundary" (Str.string_match r "sayhelloworld" 3);

  let r = Str.regexp {|x*|} in
  print_bool "x* -> ''" (Str.string_match r "" 0);
  print_bool "x* -> 'y'" (Str.string_match r "y" 0);
  print_bool "x* -> 'xxx'" (Str.string_match r "xxx" 0);

  let r = Str.regexp {|hello world|} in
  print_bool "partial full match" (Str.string_partial_match r "hello world" 0);
  print_bool "partial no match" (Str.string_partial_match r "goodbye" 0);
  print_bool "partial literal prefix" (Str.string_partial_match r "hello wo" 0);
  print_string "partial literal prefix matched" (Str.matched_string "hello wo");

  let r = Str.regexp {|he.*|} in
  print_bool "partial with wildcard" (Str.string_partial_match r "hello" 0);
  print_bool "partial wildcard no match" (Str.string_partial_match r "abc" 0);

  let r = Str.regexp {|partial match|} in
  print_bool "partial empty string" (Str.string_partial_match r "" 0);
  print_bool "partial text prefix" (Str.string_partial_match r "partial m" 0);
  print_string "partial text prefix matched" (Str.matched_string "partial m");

  let r = Str.regexp {|\(partial\)\|\(match\)|} in
  print_bool "partial alternation 'part'" (Str.string_partial_match r "part" 0);
  print_bool "partial alternation 'mat'" (Str.string_partial_match r "mat" 0);
  print_bool "partial alternation no match"
    (Str.string_partial_match r "zorglub" 0);

  let r = Str.regexp {|[0-9]+abc|} in
  print_bool "partial class+literal" (Str.string_partial_match r "123a" 0);

  let r = Str.regexp {|\([a-z]+\)@\([a-z]+\)|} in
  print_bool "partial grouped email" (Str.string_partial_match r "user@" 0);

  let r = Str.regexp {|partial match|} in
  print_bool "partial non-zero start"
    (Str.string_partial_match r "zzpartial m" 2);
  print_string "partial non-zero matched" (Str.matched_string "zzpartial m");

  let r = Str.regexp {|^\([a-z]+\)@\([a-z]+\)\.\([a-z]+\)$|} in
  print_bool "email pattern" (Str.string_match r "user@example.com" 0);
  print_bool "not email" (Str.string_match r "not-an-email" 0);

  let r = Str.regexp {|\([0-9]+\)\.\([0-9]+\)\.\([0-9]+\)|} in
  print_bool "version pattern" (Str.string_match r "1.2.3" 0);
  print_bool "not version" (Str.string_match r "abc" 0)
