(*
 * Main driver code
 *)

open Llvm
open Llvm_executionengine
open Llvm_target
open Llvm_scalar_opts

let main () =
  ignore (initialize ()); 

  (* Install tandard binary operators
   * 1 is the lowest precendence *)
  Hashtbl.add Parser.binop_precedence '=' 2;
  Hashtbl.add Parser.binop_precedence '<' 10;
  Hashtbl.add Parser.binop_precedence '+' 20;
  Hashtbl.add Parser.binop_precedence '-' 20;
  Hashtbl.add Parser.binop_precedence '*' 40; (* highest *)

  (* Prime the first token *)
  print_string "ready> "; flush stdout;
  let stream = Lexer.lex (Stream.of_channel stdin) in

  (* create the JIT *)
  let the_execution_engine = create Codegen.the_module in
  let the_fpm = PassManager.create_function Codegen.the_module in

  (* Set up the optimizer pipeline *)

  (* Promote allocas to registers *)
  add_memory_to_register_promotion the_fpm;

  (* Do simple "peephole" optimizations and bit-twiddling optzn *)
  add_instruction_combination the_fpm;

  (* Reassociate expressions *)
  add_reassociation the_fpm;

  (* Eliminate common subexpressions *)
  add_gvn the_fpm;

  (* Simplify the control flow (deleting unreachable block, etc) *)
  add_cfg_simplification the_fpm;

  ignore(PassManager.initialize the_fpm);

  (* Run the main "interpreter loop" now *)
  Toplevel.main_loop the_fpm the_execution_engine stream;

  (* Print out all the generated code *)
  dump_module Codegen.the_module
;;

main ()
