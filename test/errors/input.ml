let try_exn label f =
  try
    f ();
    Printf.printf "%s: ok\n" label
  with
  | Not_found -> Printf.printf "%s: Not_found\n" label
  | Invalid_argument msg -> Printf.printf "%s: Invalid_argument(%s)\n" label msg
  | Failure msg -> Printf.printf "%s: Failure(%s)\n" label msg

let setup_match () =
  let r = Str.regexp {|\(hello\) \(world\)|} in
  ignore (Str.string_match r "hello world" 0)

let setup_alternation () =
  let r = Str.regexp {|\(a\)\|b|} in
  ignore (Str.string_match r "b" 0)

let () =
  try_exn "matched_string" (fun () -> ignore (Str.matched_string "x"));
  try_exn "matched_group 0" (fun () -> ignore (Str.matched_group 0 "x"));
  try_exn "matched_group 1" (fun () -> ignore (Str.matched_group 1 "x"));
  try_exn "match_beginning" (fun () -> ignore (Str.match_beginning ()));
  try_exn "match_end" (fun () -> ignore (Str.match_end ()));
  try_exn "group_beginning 0" (fun () -> ignore (Str.group_beginning 0));
  try_exn "group_beginning 1" (fun () -> ignore (Str.group_beginning 1));
  try_exn "group_end 0" (fun () -> ignore (Str.group_end 0));
  try_exn "group_end 1" (fun () -> ignore (Str.group_end 1));

  let r = Str.regexp {|xyz|} in
  ignore (Str.string_match r "abc" 0);
  try_exn "matched_string" (fun () -> ignore (Str.matched_string "abc"));
  try_exn "matched_group 0" (fun () -> ignore (Str.matched_group 0 "abc"));
  try_exn "match_beginning" (fun () -> ignore (Str.match_beginning ()));
  try_exn "match_end" (fun () -> ignore (Str.match_end ()));
  try_exn "group_beginning 0" (fun () -> ignore (Str.group_beginning 0));
  try_exn "group_end 0" (fun () -> ignore (Str.group_end 0));

  setup_match ();
  try_exn "matched_group 3" (fun () ->
      ignore (Str.matched_group 3 "hello world"));
  try_exn "matched_group 99" (fun () ->
      ignore (Str.matched_group 99 "hello world"));
  try_exn "group_beginning 3" (fun () -> ignore (Str.group_beginning 3));
  try_exn "group_end 3" (fun () -> ignore (Str.group_end 3));

  setup_match ();
  try_exn "matched_group -1" (fun () ->
      ignore (Str.matched_group (-1) "hello world"));
  try_exn "group_beginning -1" (fun () -> ignore (Str.group_beginning (-1)));
  try_exn "group_end -1" (fun () -> ignore (Str.group_end (-1)));

  setup_alternation ();
  Printf.printf "matched_group 0: %s\n" (Str.matched_group 0 "b");
  try_exn "matched_group 1" (fun () -> ignore (Str.matched_group 1 "b"));
  try_exn "group_beginning 1" (fun () -> ignore (Str.group_beginning 1));
  try_exn "group_end 1" (fun () -> ignore (Str.group_end 1));

  ignore (Str.string_match (Str.regexp "xyz") "abc" 0);
  try_exn "replace_matched" (fun () ->
      ignore (Str.replace_matched {|\0|} "hello"));

  try_exn "before -1" (fun () -> ignore (Str.string_before "hello" (-1)));
  try_exn "before 10" (fun () -> ignore (Str.string_before "hello" 10));
  try_exn "before 5" (fun () ->
      Printf.printf "ok: %s\n" (Str.string_before "hello" 5));

  try_exn "after -1" (fun () -> ignore (Str.string_after "hello" (-1)));
  try_exn "after 10" (fun () -> ignore (Str.string_after "hello" 10));
  try_exn "after 5" (fun () ->
      Printf.printf "ok: %s\n" (Str.string_after "hello" 5));

  try_exn "first -1" (fun () -> ignore (Str.first_chars "hello" (-1)));
  try_exn "first 10" (fun () -> ignore (Str.first_chars "hello" 10));
  try_exn "first 0" (fun () ->
      Printf.printf "ok: [%s]\n" (Str.first_chars "hello" 0));

  try_exn "last -1" (fun () -> ignore (Str.last_chars "hello" (-1)));
  try_exn "last 10" (fun () -> ignore (Str.last_chars "hello" 10));
  try_exn "last 0" (fun () ->
      Printf.printf "ok: [%s]\n" (Str.last_chars "hello" 0));

  try_exn "no match" (fun () ->
      ignore (Str.search_forward (Str.regexp {|xyz|}) "abc" 0));
  try_exn "empty string" (fun () ->
      ignore (Str.search_forward (Str.regexp {|a|}) "" 0));

  try_exn "no match" (fun () ->
      ignore (Str.search_backward (Str.regexp {|xyz|}) "abc" 2));
  try_exn "empty string" (fun () ->
      ignore (Str.search_backward (Str.regexp {|a|}) "" 0));

  setup_match ();
  Printf.printf "before: %s\n" (Str.matched_string "hello world");
  (try ignore (Str.search_forward (Str.regexp {|xyz|}) "abc" 0)
   with Not_found -> ());
  try_exn "after failed search" (fun () ->
      ignore (Str.matched_string "hello world"));

  let r = Str.regexp {|\([a-z]+\)|} in
  let _ = Str.search_forward r "abc def" 0 in
  Printf.printf "first: %s\n" (Str.matched_group 1 "abc def");
  let _ = Str.search_forward r "abc def" 4 in
  Printf.printf "second: %s\n" (Str.matched_group 1 "abc def");

  let r = Str.regexp {|xyz|} in
  Printf.printf "no match returns false: %b\n" (Str.string_match r "abc" 0);

  let r = Str.regexp {|\(\(a\)b\)\|c|} in
  let _ = Str.string_match r "c" 0 in
  Printf.printf "matched: %s\n" (Str.matched_group 0 "c");
  try_exn "outer group" (fun () -> ignore (Str.matched_group 1 "c"));
  try_exn "inner group" (fun () -> ignore (Str.matched_group 2 "c"))
