let print_string label s = Printf.printf "%s: %s\n" label s
let print_int label n = Printf.printf "%s: %d\n" label n

let () =
  print_string "before 5" (Str.string_before "hello world" 5);
  print_string "before 0" (Str.string_before "hello world" 0);
  print_string "before 11" (Str.string_before "hello world" 11);

  print_string "after 6" (Str.string_after "hello world" 6);
  print_string "after 0" (Str.string_after "hello world" 0);
  print_string "after 11" (Str.string_after "hello world" 11);

  print_string "first 3" (Str.first_chars "hello" 3);
  print_string "first 0" (Str.first_chars "hello" 0);
  print_string "first 5" (Str.first_chars "hello" 5);

  print_string "last 3" (Str.last_chars "hello" 3);
  print_string "last 0" (Str.last_chars "hello" 0);
  print_string "last 5" (Str.last_chars "hello" 5);

  let s = "hello world" in
  for n = 0 to String.length s do
    let b = Str.string_before s n in
    let f = Str.first_chars s n in
    if b <> f then
      Printf.printf "MISMATCH at %d: string_before=%s first_chars=%s\n" n b f
  done;
  print_endline "all equal";

  print_string "before 0 empty" (Str.string_before "" 0);
  print_string "after 0 empty" (Str.string_after "" 0);
  print_string "first 0 empty" (Str.first_chars "" 0);
  print_string "last 0 empty" (Str.last_chars "" 0);

  print_string "quote special" (Str.quote "a.b*c+d?e[f]^g$h|i(j)k{l}");
  print_string "quote plain" (Str.quote "hello");
  print_string "quote backslash" (Str.quote "a\\b");
  print_string "quote empty" (Str.quote "");

  let test_roundtrip s =
    let r = Str.regexp (Str.quote s) in
    let matches = Str.string_match r s 0 in
    Printf.printf "roundtrip %S: %b\n" s matches
  in
  test_roundtrip "a.b*c+d?";
  test_roundtrip "hello world";
  test_roundtrip "foo[bar]";
  test_roundtrip "(1+2)*3";
  test_roundtrip "a\\b";
  test_roundtrip "";

  let s = "hello world" in
  let mid = String.length s / 2 in
  print_string "before mid" (Str.string_before s mid);
  print_string "after mid" (Str.string_after s mid);
  print_int "length before + length after"
    (String.length (Str.string_before s mid)
    + String.length (Str.string_after s mid))
