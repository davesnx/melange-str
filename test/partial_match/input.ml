let print_bool label b = Printf.printf "%s: %b\n" label b
let print_exn label f =
  try
    f ();
    Printf.printf "%s: ok\n" label
  with
  | Invalid_argument msg -> Printf.printf "%s: Invalid_argument(%s)\n" label msg
  | Not_found -> Printf.printf "%s: Not_found\n" label

let print_matched_if_any label input =
  try Printf.printf "%s: %s\n" label (Str.matched_string input)
  with Invalid_argument _ -> Printf.printf "%s: <none>\n" label

let () =
  let r = Str.regexp {|partial match|} in
  print_bool "literal empty" (Str.string_partial_match r "" 0);
  print_matched_if_any "literal empty matched" "";
  print_bool "literal full" (Str.string_partial_match r "partial match" 0);
  print_matched_if_any "literal full matched" "partial match";
  print_bool "literal prefix" (Str.string_partial_match r "partial m" 0);
  print_matched_if_any "literal prefix matched" "partial m";
  print_bool "literal no match" (Str.string_partial_match r "zorglub" 0);
  print_matched_if_any "literal no match matched" "zorglub";

  let r = Str.regexp {|\(partial\)\|\(match\)|} in
  print_bool "alt empty" (Str.string_partial_match r "" 0);
  print_matched_if_any "alt empty matched" "";
  print_bool "alt part" (Str.string_partial_match r "part" 0);
  print_matched_if_any "alt part matched" "part";
  print_bool "alt mat" (Str.string_partial_match r "mat" 0);
  print_matched_if_any "alt mat matched" "mat";
  print_bool "alt full partial" (Str.string_partial_match r "partial" 0);
  print_matched_if_any "alt full partial matched" "partial";
  print_bool "alt full match" (Str.string_partial_match r "matching" 0);
  print_matched_if_any "alt full match matched" "matching";
  print_bool "alt no match" (Str.string_partial_match r "zorglub" 0);
  print_matched_if_any "alt no match matched" "zorglub";

  let r = Str.regexp {|hello world|} in
  print_bool "offset prefix" (Str.string_partial_match r "zzhello wo" 2);
  print_matched_if_any "offset prefix matched" "zzhello wo";

  let r = Str.regexp {|[0-9]+abc|} in
  print_bool "class tail" (Str.string_partial_match r "123a" 0);
  print_matched_if_any "class tail matched" "123a";

  let r = Str.regexp {|\([a-z]+\)@\([a-z]+\)|} in
  print_bool "group tail" (Str.string_partial_match r "user@" 0);
  print_matched_if_any "group tail matched" "user@";

  let r = Str.regexp {|^hello world|} in
  print_bool "anchored prefix" (Str.string_partial_match r "hello wo" 0);
  print_matched_if_any "anchored prefix matched" "hello wo";

  let r = Str.regexp {|hello|} in
  print_exn "invalid pos" (fun () ->
      ignore (Str.string_partial_match r "hello" 99));
  print_matched_if_any "invalid pos matched" "hello"
