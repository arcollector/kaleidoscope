build:
	ocamlbuild lexer.byte

build_2:
	ocamlbuild lexer_2.byte

build_3:
	ocamlbuild toy.byte

example:
	ocamlfind ocamlc -syntax camlp4o -package camlp4 token.ml lexer_2.ml -o lexer_2
