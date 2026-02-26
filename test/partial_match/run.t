  $ ./input.exe
  literal empty: true
  literal empty matched: 
  literal full: true
  literal full matched: partial match
  literal prefix: true
  literal prefix matched: partial m
  literal no match: false
  literal no match matched: <none>
  alt empty: true
  alt empty matched: 
  alt part: true
  alt part matched: part
  alt mat: true
  alt mat matched: mat
  alt full partial: true
  alt full partial matched: partial
  alt full match: true
  alt full match matched: match
  alt no match: false
  alt no match matched: <none>
  offset prefix: true
  offset prefix matched: hello wo
  class tail: true
  class tail matched: 123a
  group tail: true
  group tail matched: user@
  anchored prefix: true
  anchored prefix matched: hello wo
  invalid pos: Invalid_argument(Str.string_partial_match)
  invalid pos matched: <none>
  $ ./input.exe > native.out && diff --strip-trailing-cr native.out js.out
