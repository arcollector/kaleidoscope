# Before anything

> sudo apt-get install llvm

# Opam dependences

> opam install ctypes ctypes-foreign
> opam install llvm

# How to view CFG files

> sudo apt-get install graphviz
> llvm-as < t.ll | opt -analyze -view-cfg 
> dot t.ll -Tpng > if.png
