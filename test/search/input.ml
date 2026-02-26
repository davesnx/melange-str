let print_int label n = Printf.printf "%s: %d\n" label n

let try_search label f =
  try
    let pos = f () in
    Printf.printf "%s: %d\n" label pos
  with Not_found -> Printf.printf "%s: Not_found\n" label

let () =
  let r = Str.regexp {|world|} in
  try_search "find 'world'" (fun () -> Str.search_forward r "hello world" 0);

  let r = Str.regexp {|[0-9]+|} in
  try_search "first number" (fun () -> Str.search_forward r "abc 123 def 456" 0);
  try_search "from pos 5" (fun () -> Str.search_forward r "abc 123 def 456" 5);
  try_search "from pos 8" (fun () -> Str.search_forward r "abc 123 def 456" 8);

  let r = Str.regexp {|xyz|} in
  try_search "not found" (fun () -> Str.search_forward r "hello world" 0);

  let r = Str.regexp {|world|} in
  let _ = Str.search_forward r "hello world" 0 in
  print_int "match_beginning" (Str.match_beginning ());
  print_int "match_end" (Str.match_end ());
  Printf.printf "matched_string: %s\n" (Str.matched_string "hello world");

  let r = Str.regexp {|\([a-z]+\)=\([0-9]+\)|} in
  try_search "key=val" (fun () -> Str.search_forward r "foo x=42 bar" 0);
  Printf.printf "group 1: %s\n" (Str.matched_group 1 "foo x=42 bar");
  Printf.printf "group 2: %s\n" (Str.matched_group 2 "foo x=42 bar");

  let r = Str.regexp {|[0-9]+|} in
  try_search "from end" (fun () ->
      Str.search_backward r "abc 123 def 456 ghi" 18);

  let r = Str.regexp {|[0-9]+|} in
  try_search "from 10" (fun () ->
      Str.search_backward r "abc 123 def 456 ghi" 10);

  let r = Str.regexp {|xyz|} in
  try_search "not found" (fun () -> Str.search_backward r "hello world" 10);

  let r = Str.regexp {|[a-z]+|} in
  let pos = Str.search_backward r "123 abc 456 def" 14 in
  Printf.printf "position: %d\n" pos;
  Printf.printf "matched_string: %s\n" (Str.matched_string "123 abc 456 def");
  print_int "match_beginning" (Str.match_beginning ());
  print_int "match_end" (Str.match_end ());

  let r = Str.regexp {|[a-z]+|} in
  let s = "123 abc 456 def 789 ghi" in
  let pos1 = Str.search_forward r s 0 in
  Printf.printf "first: %d (%s)\n" pos1 (Str.matched_string s);
  let pos2 = Str.search_forward r s (Str.match_end ()) in
  Printf.printf "second: %d (%s)\n" pos2 (Str.matched_string s);
  let pos3 = Str.search_forward r s (Str.match_end ()) in
  Printf.printf "third: %d (%s)\n" pos3 (Str.matched_string s);
  try_search "fourth" (fun () -> Str.search_forward r s (Str.match_end ()))
