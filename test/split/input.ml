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
  let r = Str.regexp {| +|} in
  print_list "spaces" (Str.split r "hello world test");

  let r = Str.regexp {|[,;]+|} in
  print_list "comma/semi" (Str.split r "a,b;c,,d");

  let r = Str.regexp {| +|} in
  print_list "trimmed" (Str.split r "  hello  world  ");

  let r = Str.regexp {| |} in
  print_list "empty" (Str.split r "");

  let r = Str.regexp {|x|} in
  print_list "no match" (Str.split r "abc");

  let r = Str.regexp {|:|} in
  print_list "colon" (Str.split r "a:b:c:d");

  let r = Str.regexp {| |} in
  print_list "delim" (Str.split_delim r "hello world");

  let r = Str.regexp {| |} in
  print_list "boundaries" (Str.split_delim r " hello world ");

  let r = Str.regexp {| |} in
  print_list "empty delim" (Str.split_delim r "");

  let r = Str.regexp {| |} in
  print_list "limit 3" (Str.bounded_split r "a b c d e" 3);

  let r = Str.regexp {| |} in
  print_list "limit 2" (Str.bounded_split r "a b c" 2);

  let r = Str.regexp {| |} in
  print_list "limit 1" (Str.bounded_split r "a b c" 1);

  let r = Str.regexp {| |} in
  print_list "bounded delim 3" (Str.bounded_split_delim r "a b c d e" 3);

  let r = Str.regexp {| |} in
  print_list "bounded delim boundaries" (Str.bounded_split_delim r " a b c " 2);

  let r = Str.regexp {|[,;]|} in
  print_split_results "full" (Str.full_split r "a,b;c");

  let r = Str.regexp {| |} in
  print_split_results "full boundaries" (Str.full_split r " hello world ");

  let r = Str.regexp {|x|} in
  print_split_results "no match" (Str.full_split r "abc");

  let r = Str.regexp {|[,;]|} in
  print_split_results "bounded full 2" (Str.bounded_full_split r "a,b;c,d" 2);

  let r = Str.regexp {|[,;]|} in
  print_split_results "bounded full 1" (Str.bounded_full_split r "a,b;c" 1);

  let r = Str.regexp {|,|} in
  print_list "consecutive" (Str.split r "a,,b,,,c");

  let r = Str.regexp {|,|} in
  print_list "delim consecutive" (Str.split_delim r "a,,b,,,c");

  let r = Str.regexp {|,|} in
  print_split_results "full consecutive" (Str.full_split r "a,,b")
