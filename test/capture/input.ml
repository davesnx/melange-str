let print_bool label b = Printf.printf "%s: %b\n" label b
let print_string label s = Printf.printf "%s: %s\n" label s
let print_int label n = Printf.printf "%s: %d\n" label n

let () =
  let r = Str.regexp {|hello \([a-z]+\)|} in
  let _ = Str.string_match r "hello world" 0 in
  print_string "matched_string" (Str.matched_string "hello world");
  print_string "group 1" (Str.matched_group 1 "hello world");

  let r = Str.regexp {|\([0-9]+\)-\([0-9]+\)|} in
  let _ = Str.string_match r "123-456" 0 in
  print_string "group 0" (Str.matched_group 0 "123-456");
  print_string "group 1" (Str.matched_group 1 "123-456");
  print_string "group 2" (Str.matched_group 2 "123-456");

  let r = Str.regexp {|\([a-z]+\)@\([a-z]+\)\.\([a-z]+\)|} in
  let _ = Str.string_match r "user@example.com" 0 in
  print_string "group 0" (Str.matched_group 0 "user@example.com");
  print_string "group 1" (Str.matched_group 1 "user@example.com");
  print_string "group 2" (Str.matched_group 2 "user@example.com");
  print_string "group 3" (Str.matched_group 3 "user@example.com");

  let r = Str.regexp {|\(a\(b\)c\)|} in
  let _ = Str.string_match r "abc" 0 in
  print_string "group 0" (Str.matched_group 0 "abc");
  print_string "group 1" (Str.matched_group 1 "abc");
  print_string "group 2" (Str.matched_group 2 "abc");

  let r = Str.regexp {|world|} in
  let _ = Str.string_match r "hello world" 6 in
  print_int "match_beginning" (Str.match_beginning ());
  print_int "match_end" (Str.match_end ());

  let r = Str.regexp {|[0-9]+|} in
  let _ = Str.search_forward r "abc 123 def" 0 in
  print_int "search match_beginning" (Str.match_beginning ());
  print_int "search match_end" (Str.match_end ());

  let r = Str.regexp {|hello \([a-z]+\) world|} in
  let _ = Str.string_match r "hello test world" 0 in
  print_int "group 0 beginning" (Str.group_beginning 0);
  print_int "group 0 end" (Str.group_end 0);
  print_int "group 1 beginning" (Str.group_beginning 1);
  print_int "group 1 end" (Str.group_end 1);

  let r = Str.regexp {|\(foo\)\|bar|} in
  let _ = Str.string_match r "foo" 0 in
  print_string "alt group 1 on 'foo'" (Str.matched_group 1 "foo");

  let r = Str.regexp {|\([a-z]+\)|} in
  let _ = Str.search_forward r "123 abc 456" 0 in
  print_string "group 1" (Str.matched_group 1 "123 abc 456");
  print_int "group 1 beginning" (Str.group_beginning 1);
  print_int "group 1 end" (Str.group_end 1);

  let r = Str.regexp {|\(foo\)\|bar|} in
  let _ = Str.string_match r "bar" 0 in
  (try
     let _ = Str.matched_group 1 "bar" in
     print_endline "group 1: matched (unexpected)"
   with Not_found -> print_endline "group 1: Not_found");

  let r = Str.regexp {|[a-z]+|} in
  let _ = Str.string_match r "hello" 0 in
  print_string "group 0" (Str.matched_group 0 "hello");
  print_bool "group 0 = matched_string" (Str.matched_group 0 "hello" = Str.matched_string "hello")
