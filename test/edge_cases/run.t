  $ ./input.exe
  no prior match: Invalid_argument(Str.matched_group)
  no prior match group: Invalid_argument(Str.matched_group)
  no prior match_beginning: Invalid_argument(Str.group_beginning)
  search past end: Not_found
  backward no match: Not_found
  group 1 on no-group pattern: Invalid_argument(Str.matched_group)
  empty match at end: true
  non-empty match at end: false
  dot matches space: true
  dot doesn't match newline: false
  ^ at string start: true
  aabaa matches: true
  aaba doesn't match: false
  aba matches: true
  empty match pos: 0
  empty match string: 
  match 1: pos=0 key=x val=1
  match 2: pos=4 key=y val=2
  match 3: pos=8 key=z val=3
  no more matches: Not_found
  dedup: hello world
  empty pattern insert: -a-b-
  leading delim:
    [a]
    [b]
  trailing delim:
    [a]
    [b]
  only delims:
    []
  single element:
    [abc]
  delim leading:
    []
    [a]
    [b]
  delim trailing:
    [a]
    [b]
    []
  delim only:
    []
    []
    []
  delim single:
    [abc]
  full leading:
    Delim(,)
    Text(a)
    Delim(,)
    Text(b)
  full trailing:
    Text(a)
    Delim(,)
    Text(b)
    Delim(,)
  full only delims:
    Delim(,)
    Delim(,)
  bounded 0:
    [a]
    [b]
    [c]
  bounded 10:
    [a]
    [b]
    [c]
  bounded delim 10:
    [a]
    [b]
    [c]
  bounded full 10:
    Text(a)
    Delim( )
    Text(b)
    Delim( )
    Text(c)
  global_sub no match: hello world
  sub_first no match: hello world
  dash in class: true
  complex class: true
  complex class digit: true
  complex class reject: false
  replace with backslash: a\b
  group 1 after success: hello
  group after fail: Invalid_argument(Str.matched_group)
  g1 begin: 0
  g1 end: 1
  g2 begin: 2
  g2 end: 4
  g3 begin: 5
  g3 end: 8
  matched: (42)
  g0 begin: 4
  g0 end: 8
  g1 begin: 5
  g1 end: 7
  first match: 123
  resume at 5: 5
  resumed match: 23
  case swap: hELLO wORLD fOO
  all specials literal: true
  all specials no wildcard: false

  $ ./input.exe > native.out && diff native.out js.out
