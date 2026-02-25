  $ ./input.exe
  spaces:
    [hello]
    [world]
    [test]
  comma/semi:
    [a]
    [b]
    [c]
    [d]
  trimmed:
    [hello]
    [world]
  empty:
  no match:
    [abc]
  colon:
    [a]
    [b]
    [c]
    [d]
  delim:
    [hello]
    [world]
  boundaries:
    []
    [hello]
    [world]
    []
  empty delim:
  limit 3:
    [a]
    [b]
    [c d e]
  limit 2:
    [a]
    [b c]
  limit 1:
    [a b c]
  bounded delim 3:
    [a]
    [b]
    [c d e]
  bounded delim boundaries:
    []
    [a b c ]
  full:
    Text(a)
    Delim(,)
    Text(b)
    Delim(;)
    Text(c)
  full boundaries:
    Delim( )
    Text(hello)
    Delim( )
    Text(world)
    Delim( )
  no match:
    Text(abc)
  bounded full 2:
    Text(a)
    Delim(,)
    Text(b;c,d)
  bounded full 1:
    Text(a,b;c)
  consecutive:
    [a]
    []
    [b]
    []
    []
    [c]
  delim consecutive:
    [a]
    []
    [b]
    []
    []
    [c]
  full consecutive:
    Text(a)
    Delim(,)
    Delim(,)
    Text(b)
  $ ./input.exe > native.out && diff native.out js.out
