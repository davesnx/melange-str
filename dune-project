(lang dune 3.8)

(using melange 0.1)

(generate_opam_files true)

(package
 (name melange-str)
 (depends
  (ocaml
   (>= 5.0))
  (melange
   (>= 6.0))
  (ocaml-lsp-server :with-dev-setup)
  (ocamlformat :with-dev-setup)))
