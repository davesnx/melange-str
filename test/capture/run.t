  $ ./input.exe
  matched_string: hello world
  group 1: world
  group 0: 123-456
  group 1: 123
  group 2: 456
  group 0: user@example.com
  group 1: user
  group 2: example
  group 3: com
  group 0: abc
  group 1: abc
  group 2: b
  match_beginning: 6
  match_end: 11
  search match_beginning: 4
  search match_end: 7
  group 0 beginning: 0
  group 0 end: 16
  group 1 beginning: 6
  group 1 end: 10
  alt group 1 on 'foo': foo
  group 1: abc
  group 1 beginning: 4
  group 1 end: 7
  group 1: Not_found
  group 0: hello
  group 0 = matched_string: true
  $ ./input.exe > native.out && diff --strip-trailing-cr native.out js.out
