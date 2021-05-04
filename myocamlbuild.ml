open Ocamlbuild_plugin;;
flag ["link"; "ocaml"; "g++"] (S[A"-cc"; A"g++ -rdynamic"]);;
dep ["link"; "ocaml"; "use_bindings"] ["bindings.o"];;