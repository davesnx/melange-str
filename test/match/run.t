  $ ./input.exe
  match 'hello' at 0: true
  match 'hello' at 1: false
  match 'hello' in 'say hello': false
  match 'world' at 0: false
  match 'world' at 6: true
  HELLO: true
  Hello: true
  hElLo: true
  case fold [a-z]+ on 'ABC': true
  literal 'a.b+c': true
  not pattern 'aXbbc': false
  matches 'hello': true
  matches 'HELLO': true
  quoted literal: true
  quoted no wildcard: false
  a.c -> 'abc': true
  a.c -> 'a1c': true
  a.c -> 'ac': false
  [0-9]+ -> '123': true
  [0-9]+ -> 'abc': false
  [^0-9]+ -> 'abc': true
  [^0-9]+ -> '123': false
  identifier -> 'foo_bar': true
  identifier -> '_x1': true
  identifier -> '1abc': false
  ab*c -> 'ac': true
  ab*c -> 'abc': true
  ab*c -> 'abbc': true
  ab+c -> 'ac': false
  ab+c -> 'abc': true
  ab+c -> 'abbc': true
  ab?c -> 'ac': true
  ab?c -> 'abc': true
  ab?c -> 'abbc': false
  foo|bar -> 'foo': true
  foo|bar -> 'bar': true
  foo|bar -> 'baz': false
  a|b|c -> 'a': true
  a|b|c -> 'b': true
  a|b|c -> 'c': true
  a|b|c -> 'd': false
  ^hello at start: true
  ^hello not at start: false
  a\.b -> 'a.b': true
  a\.b -> 'axb': false
  a\\b -> 'a\b': true
  \b at word boundary: true
  \b not at boundary: false
  x* -> '': true
  x* -> 'y': true
  x* -> 'xxx': true
  partial full match: true
  partial no match: false
  partial literal prefix: true
  partial literal prefix matched: hello wo
  partial with wildcard: true
  partial wildcard no match: false
  partial empty string: true
  partial text prefix: true
  partial text prefix matched: partial m
  partial alternation 'part': true
  partial alternation 'mat': true
  partial alternation no match: false
  partial class+literal: true
  partial grouped email: true
  partial non-zero start: true
  partial non-zero matched: partial m
  email pattern: true
  not email: false
  version pattern: true
  not version: false
  $ ./input.exe > native.out && diff native.out js.out
