# Kaleidscope - Implementing a language with LLVM in OCaml (2021)

Written in Ocaml, version 4.12.0

# Before anything

> sudo apt-get install llvm

# Opam dependences

> opam install ctypes ctypes-foreign
> opam install llvm
> opam install camlp4

# How to view CFG files

> sudo apt-get install graphviz
> llvm-as < t.ll | opt -analyze -view-cfg 
> dot t.ll -Tpng > if.png
