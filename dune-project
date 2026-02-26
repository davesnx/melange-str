(lang dune 3.8)

(name melange-str)

(using melange 0.1)

(generate_opam_files true)

(package
 (name melange-str)
 (synopsis "Str module for Melange")
 (description
  "Implementation of Str module for Melange, using JavaScript's `RegExp` as the backend.")
 (maintainers "David Sancho <dsnxmoreno@gmail.com>")
 (authors "David Sancho <dsnxmoreno@gmail.com>")
 (license "MIT")
 (homepage "https://github.com/davesnx/melange-str")
 (bug_reports "https://github.com/davesnx/melange-str/issues")
 (source (github davesnx/melange-str))
 (depends
  (ocaml
   (>= 5.0))
  (melange
   (>= 6.0))
  (ocaml-lsp-server :with-dev-setup)
  (ocamlformat :with-dev-setup)))
