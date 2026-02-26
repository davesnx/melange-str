  $ ./input.exe
  all replaced: bar bar bar
  swap: world hello
  bracket: [hello] [world]
  swapped: badc
  first only: bar foo foo
  first swap: world hello foo bar
  unchanged: hello world
  unchanged: hello world
  doubled: a 20 b 40 c 60
  first doubled: a 20 b 20 c 30
  transformed: X:1 Y:2 Z:3
  template: 123-hello
  whole match: [hello]
  empty pattern on 'abc': -a-b-c-
  $ ./input.exe > native.out && diff --strip-trailing-cr native.out js.out
