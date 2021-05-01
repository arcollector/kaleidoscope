toy:
	ocamlbuild -tag thread -use-ocamlfind -pkgs llvm,llvm.analysis,llvm.executionengine,llvm.target,llvm.scalar_opts toy.native
