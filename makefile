build:
	ocamlbuild lexer.byte

build_2:
	ocamlbuild lexer_2.byte

codegen:
	ocamlfind ocamlopt -package llvm -package llvm.analysis -linkpkg ast.ml codegen.ml

toy:
	ocamlbuild -tag thread -use-ocamlfind -pkgs llvm,llvm.analysis,llvm.executionengine,llvm.target,llvm.scalar_opts toy.native

example:
	ocamlfind ocamlc -syntax camlp4o -package camlp4 token.ml lexer_2.ml -o lexer_2
