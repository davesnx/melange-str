  $ ./input.exe
  find 'world': 6
  first number: 4
  from pos 5: 5
  from pos 8: 12
  not found: Not_found
  match_beginning: 6
  match_end: 11
  matched_string: world
  key=val: 4
  group 1: x
  group 2: 42
  from end: 14
  from 10: 6
  not found: Not_found
  position: 14
  matched_string: f
  match_beginning: 14
  match_end: 15
  first: 4 (abc)
  second: 12 (def)
  third: 20 (ghi)
  fourth: Not_found
  $ ./input.exe > native.out && diff --strip-trailing-cr native.out js.out
