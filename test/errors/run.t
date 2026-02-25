  $ ./input.exe
  matched_string: Invalid_argument(Str.matched_group)
  matched_group 0: Invalid_argument(Str.matched_group)
  matched_group 1: Invalid_argument(Str.matched_group)
  match_beginning: Invalid_argument(Str.group_beginning)
  match_end: Invalid_argument(Str.group_end)
  group_beginning 0: Invalid_argument(Str.group_beginning)
  group_beginning 1: Invalid_argument(Str.group_beginning)
  group_end 0: Invalid_argument(Str.group_end)
  group_end 1: Invalid_argument(Str.group_end)
  matched_string: Invalid_argument(Str.matched_group)
  matched_group 0: Invalid_argument(Str.matched_group)
  match_beginning: Invalid_argument(Str.group_beginning)
  match_end: Invalid_argument(Str.group_end)
  group_beginning 0: Invalid_argument(Str.group_beginning)
  group_end 0: Invalid_argument(Str.group_end)
  matched_group 3: Invalid_argument(Str.matched_group)
  matched_group 99: Invalid_argument(Str.matched_group)
  group_beginning 3: Invalid_argument(Str.group_beginning)
  group_end 3: Invalid_argument(Str.group_end)
  matched_group -1: Invalid_argument(Str.matched_group)
  group_beginning -1: Invalid_argument(Str.group_beginning)
  group_end -1: Invalid_argument(Str.group_end)
  matched_group 0: b
  matched_group 1: Not_found
  group_beginning 1: Not_found
  group_end 1: Not_found
  replace_matched: Failure(Str.replace: reference to unmatched group)
  before -1: Invalid_argument(String.sub / Bytes.sub)
  before 10: Invalid_argument(String.sub / Bytes.sub)
  ok: hello
  before 5: ok
  after -1: Invalid_argument(String.sub / Bytes.sub)
  after 10: Invalid_argument(String.sub / Bytes.sub)
  ok: 
  after 5: ok
  first -1: Invalid_argument(String.sub / Bytes.sub)
  first 10: Invalid_argument(String.sub / Bytes.sub)
  ok: []
  first 0: ok
  last -1: Invalid_argument(String.sub / Bytes.sub)
  last 10: Invalid_argument(String.sub / Bytes.sub)
  ok: []
  last 0: ok
  no match: Not_found
  empty string: Not_found
  no match: Not_found
  empty string: Not_found
  before: hello world
  after failed search: Invalid_argument(Str.matched_group)
  first: abc
  second: def
  no match returns false: false
  matched: c
  outer group: Not_found
  inner group: Not_found
  $ ./input.exe > native.out && diff native.out js.out
