let debug = ref false

let rec lex = parser
  (* skip whitespaces *)
  | [< ' (' ' | '\n' | '\r' | '\t') ; stream >] ->
    if !debug then print_string "skip whitespaces\n" ;
    [< lex stream >]

  (* identifier: [a-zA-Z][a-zA-Z0-9] *)
  | [< ' ('A' .. 'Z' | 'a' .. 'z' as char) ; stream >] ->
    if !debug then print_string "identifier\n" ;
    let buffer = Buffer.create 1 in
    Buffer.add_char buffer char ;
    lex_ident buffer stream

  (* number: [0-9.]+ *)
  | [< ' ('0' .. '9' as char) ; stream >] ->
    if !debug then print_string "number\n" ;
    let buffer = Buffer.create 1 in
    Buffer.add_char buffer char ;
    lex_number buffer stream

  (* comment until end of line *)
  | [< ' ('#'); stream >] ->
    lex_comment stream

  | [< ' char; stream >] ->
    if !debug then print_string "char\n" ;
    (* stream are lazy, so lex strem will only be evaulated when required *)
    [< 'Token.Kwd char; lex stream >]

  (* EOF syntax *)
  | [< >] ->
    [< >]

and lex_ident buffer = parser
  | [< ' ('a' .. 'z' | 'A' .. 'Z' | '0' .. '9' as char) ; stream >] ->
    if !debug then print_string "\tindentifier-eating\n" ;
    Buffer.add_char buffer char ;
    lex_ident buffer stream
  | [< stream >] ->
    if !debug then print_string "\tindentifier-done\n" ;
    match Buffer.contents buffer with
      | "def" -> [< 'Token.Def; lex stream >]
      | "extern" -> [< 'Token.Extern; lex stream >]
      | id -> [< 'Token.Ident id ; lex stream >]

and lex_number buffer = parser
  | [< ' ('0' .. '9' | '.' as char) ; stream >] ->
    if !debug then print_string "\number-eating\n" ;
    Buffer.add_char buffer char ;
    lex_number buffer stream
  | [< stream >] ->
    if !debug then print_string "\number-done\n" ;
    [< 'Token.Number (float_of_string(Buffer.contents buffer)); lex stream >]

and lex_comment = parser
  (* reached comment ends *)
  | [< ' ('\n') ; stream >] -> lex stream
  (* keep eating comment chars *)
  | [< ' c; stream >] -> lex_comment stream
  | [< >] -> [< >]


let _ =
  let stream_parsed = lex (Stream.of_string "
    def fib(x)
      if x < 3 then
        1
      else
        fib(x-1)+fib(x-2)

    # This expression will compute the 40th number.
    fib(40)
  ") in
  let rec print_stream () =
    match Stream.peek stream_parsed with
      | None -> ()
      | Some (Token.Kwd c) ->
        Stream.junk stream_parsed ;
        print_string "[Token.Kwd] " ; String.make 1 c |> print_string ; print_newline () ;
        print_stream ()
      | Some (Token.Ident s) ->
        Stream.junk stream_parsed ;
        print_string "[Token.Ident] " ; print_string s; print_newline () ;
        print_stream ()
      | Some (Token.Def) ->
        Stream.junk stream_parsed ;
        print_string "[Token.Def]\n" ;
        print_stream ()
      | Some (Token.Number n) ->
        Stream.junk stream_parsed ;
        print_string "[Token.Number] " ; string_of_float n |> print_string ; print_newline () ;
        print_stream ()
      | _ ->
        Stream.count stream_parsed |> string_of_int |> print_string ; print_newline () ;
        failwith "oops"
  in
  print_stream ()
