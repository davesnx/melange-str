  $ ./input.exe
  before 5: hello
  before 0: 
  before 11: hello world
  after 6: world
  after 0: hello world
  after 11: 
  first 3: hel
  first 0: 
  first 5: hello
  last 3: llo
  last 0: 
  last 5: hello
  all equal
  before 0 empty: 
  after 0 empty: 
  first 0 empty: 
  last 0 empty: 
  quote special: a\.b\*c\+d\?e\[f\]\^g\$h|i(j)k{l}
  quote plain: hello
  quote backslash: a\\b
  quote empty: 
  roundtrip "a.b*c+d?": true
  roundtrip "hello world": true
  roundtrip "foo[bar]": true
  roundtrip "(1+2)*3": true
  roundtrip "a\\b": true
  roundtrip "": true
  before mid: hello
  after mid:  world
  length before + length after: 11
  $ ./input.exe > native.out && diff --strip-trailing-cr native.out js.out
