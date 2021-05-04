(* 
Top-level parsing and JIT driver
*)

open Llvm
open Llvm_executionengine
open Ctypes
open PosixTypes
open Foreign

(* top ::= definition | external | expression | ';' *)
let rec main_loop the_fpm the_execution_engine stream =
  match Stream.peek stream with
  | None -> ()
  (* ignore top-level semicolons *)
  | Some (Token.Kwd ';') ->
    Stream.junk stream;
    main_loop the_fpm the_execution_engine stream
  | Some token ->
    begin
      try match token with
      | Token.Def ->
        let e = Parser.parse_definition stream in
        print_endline "parsed a function definition";
        dump_value (Codegen.codegen_func the_fpm e);
      | Token.Extern ->
        let e = Parser.parse_extern stream in
        print_endline "parsed an extern";
        dump_value (Codegen.codegen_proto e);
      | _ ->
        (* Evaluate a top-level expression into a anonymous function *)
        let e = Parser.parse_toplevel stream in
        print_endline "parsed a top-level expr";
        let the_function = Codegen.codegen_func the_fpm e in
        dump_value the_function;

        (* JIT the function. returning a function pointer *)
        let my_name = value_name the_function in
        let address = get_function_address my_name (funptr (void @-> returning double)) the_execution_engine in
        print_string "Evaluated to ";
        print_float (address ());
        print_newline();

        remove_module Codegen.the_module the_execution_engine;
        add_module  Codegen.the_module the_execution_engine;

      with
      | Stream.Error s
      | Codegen.Error s ->
        (* Skip token for error recovery *)
        Stream.junk stream;
        print_endline s;
    end;
    print_string "ready> "; flush stdout;
    main_loop the_fpm the_execution_engine stream
