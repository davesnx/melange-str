let print_bool label b = Printf.printf "%s: %b\n" label b
let print_string label s = Printf.printf "%s: %s\n" label s
let print_int label n = Printf.printf "%s: %d\n" label n

let try_exn label f =
  try
    f ();
    Printf.printf "%s: ok\n" label
  with
  | Not_found -> Printf.printf "%s: Not_found\n" label
  | Invalid_argument msg -> Printf.printf "%s: Invalid_argument(%s)\n" label msg

let print_list label lst =
  Printf.printf "%s:\n" label;
  List.iter (fun s -> Printf.printf "  [%s]\n" s) lst

let print_split_results label lst =
  Printf.printf "%s:\n" label;
  List.iter
    (function
      | Str.Text s -> Printf.printf "  Text(%s)\n" s
      | Str.Delim s -> Printf.printf "  Delim(%s)\n" s)
    lst

let () =
  try_exn "no prior match" (fun () -> ignore (Str.matched_string "hello"));

  try_exn "no prior match group" (fun () ->
      ignore (Str.matched_group 1 "hello"));

  try_exn "no prior match_beginning" (fun () -> ignore (Str.match_beginning ()));

  try_exn "search past end" (fun () ->
      ignore (Str.search_forward (Str.regexp {|x|}) "abc" 0));

  try_exn "backward no match" (fun () ->
      ignore (Str.search_backward (Str.regexp {|x|}) "abc" 2));

  let r = Str.regexp {|hello|} in
  let _ = Str.string_match r "hello" 0 in
  try_exn "group 1 on no-group pattern" (fun () ->
      ignore (Str.matched_group 1 "hello"));

  let r = Str.regexp {|x*|} in
  print_bool "empty match at end" (Str.string_match r "abc" 3);
  let r = Str.regexp {|x+|} in
  print_bool "non-empty match at end" (Str.string_match r "abc" 3);

  let r = Str.regexp {|a.b|} in
  print_bool "dot matches space" (Str.string_match r "a b" 0);
  print_bool "dot doesn't match newline" (Str.string_match r "a\nb" 0);

  let r = Str.regexp {|^hello|} in
  print_bool "^ at string start" (Str.string_match r "hello\nworld" 0);

  let r = Str.regexp {|\(a+\)b\1|} in
  print_bool "aabaa matches" (Str.string_match r "aabaa" 0);
  print_bool "aaba doesn't match" (Str.string_match r "aaba" 0);
  print_bool "aba matches" (Str.string_match r "aba" 0);

  let r = Str.regexp {|x*|} in
  let pos = Str.search_forward r "abc" 0 in
  print_int "empty match pos" pos;
  print_string "empty match string" (Str.matched_string "abc");

  let r = Str.regexp {|\([a-z]+\)=\([0-9]+\)|} in
  let s = "x=1 y=2 z=3" in
  let p1 = Str.search_forward r s 0 in
  let g1 = Str.matched_group 1 s in
  let v1 = Str.matched_group 2 s in
  Printf.printf "match 1: pos=%d key=%s val=%s\n" p1 g1 v1;
  let p2 = Str.search_forward r s (Str.match_end ()) in
  let g2 = Str.matched_group 1 s in
  let v2 = Str.matched_group 2 s in
  Printf.printf "match 2: pos=%d key=%s val=%s\n" p2 g2 v2;
  let p3 = Str.search_forward r s (Str.match_end ()) in
  let g3 = Str.matched_group 1 s in
  let v3 = Str.matched_group 2 s in
  Printf.printf "match 3: pos=%d key=%s val=%s\n" p3 g3 v3;
  try_exn "no more matches" (fun () ->
      ignore (Str.search_forward r s (Str.match_end ())));

  let r = Str.regexp {|\([a-z]+\) \1|} in
  print_string "dedup" (Str.global_replace r {|\1|} "hello hello world world");

  let r = Str.regexp {||} in
  print_string "empty pattern insert" (Str.global_replace r "-" "ab");

  let r = Str.regexp {|,|} in
  print_list "leading delim" (Str.split r ",a,b");
  print_list "trailing delim" (Str.split r "a,b,");
  print_list "only delims" (Str.split r ",,");
  print_list "single element" (Str.split r "abc");

  let r = Str.regexp {|,|} in
  print_list "delim leading" (Str.split_delim r ",a,b");
  print_list "delim trailing" (Str.split_delim r "a,b,");
  print_list "delim only" (Str.split_delim r ",,");
  print_list "delim single" (Str.split_delim r "abc");

  let r = Str.regexp {|,|} in
  print_split_results "full leading" (Str.full_split r ",a,b");
  print_split_results "full trailing" (Str.full_split r "a,b,");
  print_split_results "full only delims" (Str.full_split r ",,");

  let r = Str.regexp {| |} in
  print_list "bounded 0" (Str.bounded_split r "a b c" 0);

  let r = Str.regexp {| |} in
  print_list "bounded 10" (Str.bounded_split r "a b c" 10);

  let r = Str.regexp {| |} in
  print_list "bounded delim 10" (Str.bounded_split_delim r "a b c" 10);

  let r = Str.regexp {| |} in
  print_split_results "bounded full 10" (Str.bounded_full_split r "a b c" 10);

  let r = Str.regexp {|xyz|} in
  print_string "global_sub no match"
    (Str.global_substitute r (fun _ -> "FAIL") "hello world");
  print_string "sub_first no match"
    (Str.substitute_first r (fun _ -> "FAIL") "hello world");

  let r = Str.regexp {|[-a-z]|} in
  print_bool "dash in class" (Str.string_match r "-" 0);
  let r = Str.regexp {|[0-9a-zA-Z_]|} in
  print_bool "complex class" (Str.string_match r "_" 0);
  print_bool "complex class digit" (Str.string_match r "5" 0);
  print_bool "complex class reject" (Str.string_match r "!" 0);

  let r = Str.regexp {|x|} in
  print_string "replace with backslash" (Str.global_replace r {|\\|} "axb");

  let r = Str.regexp {|\([a-z]+\)|} in
  let _ = Str.string_match r "hello" 0 in
  print_string "group 1 after success" (Str.matched_group 1 "hello");
  let _ = Str.string_match r "123" 0 in
  try_exn "group after fail" (fun () -> ignore (Str.matched_group 1 "123"));

  let r = Str.regexp {|\([0-9]+\)\.\([0-9]+\)\.\([0-9]+\)|} in
  let _ = Str.string_match r "1.22.333" 0 in
  print_int "g1 begin" (Str.group_beginning 1);
  print_int "g1 end" (Str.group_end 1);
  print_int "g2 begin" (Str.group_beginning 2);
  print_int "g2 end" (Str.group_end 2);
  print_int "g3 begin" (Str.group_beginning 3);
  print_int "g3 end" (Str.group_end 3);

  let r = Str.regexp {|(\([0-9]+\))|} in
  let _ = Str.search_forward r "abc (42) def" 0 in
  print_string "matched" (Str.matched_string "abc (42) def");
  print_int "g0 begin" (Str.group_beginning 0);
  print_int "g0 end" (Str.group_end 0);
  print_int "g1 begin" (Str.group_beginning 1);
  print_int "g1 end" (Str.group_end 1);

  let r = Str.regexp {|[0-9]+|} in
  let s = "abc 123 def" in
  let _ = Str.search_forward r s 0 in
  print_string "first match" (Str.matched_string s);
  let pos2 = Str.search_forward r s 5 in
  print_int "resume at 5" pos2;
  print_string "resumed match" (Str.matched_string s);

  let r = Str.regexp {|\([A-Z]\)\([a-z]+\)|} in
  let result =
    Str.global_substitute r
      (fun s ->
        let initial = Str.matched_group 1 s in
        let rest = Str.matched_group 2 s in
        String.lowercase_ascii initial ^ String.uppercase_ascii rest)
      "Hello World Foo"
  in
  print_string "case swap" result;

  let specials = ".*+?[]^${}()|\\-" in
  let r = Str.regexp_string specials in
  print_bool "all specials literal" (Str.string_match r specials 0);
  print_bool "all specials no wildcard" (Str.string_match r "XXXXXXXXXXXXXXX" 0)
