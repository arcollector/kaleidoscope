(* binop_precedence - This holds the precedence for each binary operator
 * that defined *)
let binop_precedence: (char, int) Hashtbl.t = Hashtbl.create 10

(* precedence - Get the precedence of the pending binary operator token *)
let precedence c = try Hashtbl.find binop_precedence c with Not_found -> -1

(* primary
 *    ::= identifier
 *    ::= numberexpr
 *    ::= parenexpr *)
(* this funtion returns an Ast *)
let rec parse_primary = parser 
  (* numberexpr ::= number *)
  | [< 'Token.Number n >] ->
    Ast.Number n

  (* parenexpr ::= '(' expression ')' *)
  | [< 'Token.Kwd '('; e=parse_expr ; 'Token.Kwd ')' ?? "expected ')'" >] ->
    e

  (* identifierexpr
   *    ::= identifier
   *    ::= identifier '(' argumentexpr ')' *)
  | [< 'Token.Ident id; stream >] ->
    let rec parse_args accumulator = parser
      | [< e=parse_expr ; stream >] ->
        (* el begin end es para hacer codigo imperactivo
         * es como el ; pero agrupa varias lineas *)
        begin parser
          | [< 'Token.Kwd ','; e=parse_args (e::accumulator) >] -> e
          | [< >] -> e::accumulator
        end
        stream
      | [< >] -> accumulator
    in
    let rec parse_ident id = parser
      (* Call *)
      | [< 'Token.Kwd '('; args=parse_args []; 'Token.Kwd ')' ?? "expected ')'" >] ->
        Ast.Call (id, Array.of_list (List.rev args))
      (* Simple variable ref *)
      | [< >] ->
        Ast.Variable id
    in
    parse_ident id stream

  (* ifexpr ::= 'if' expr 'then' expr 'else' expr *)
  | [<
    'Token.If; c=parse_expr;
    'Token.Then ?? "expected 'then'"; t=parse_expr;
    'Token.Else ?? "expected 'else'"; e=parse_expr
  >] ->
    Ast.If (c, t, e)

  (* forexpr ::= 'for' identifier '=' expr ',' expr (',' expr)? 'in' expression *)
  | [<
    'Token.For;
    'Token.Ident id ?? "expected identifier after for";
    'Token.Kwd '=' ?? "expected '=' after for";
    stream
  >] ->
    begin parser
    | [<
      start=parse_expr;
      'Token.Kwd ',' ?? "expected ',' after for";
      end_=parse_expr
    >] ->
      let step = begin parser
      | [< 'Token.Kwd ',' ; step=parse_expr >] -> Some step
      | [< >] -> None
      end stream
      in
      begin parser
      | [< 'Token.In; body=parse_expr >] ->
        Ast.For (id, start, end_, step, body)
      | [< >] ->
        raise (Stream.Error "expected 'in' after for")
      end stream

    | [< >] ->
      raise (Stream.Error "expected '=' after for")
    end stream

  | [< >] ->
    raise (Stream.Error "unkown token when expecting an expression")

(* binoprhs
 *    ::= ('+' primary)* *)
and parse_bin_rhs expr_prec lhs stream =
  match Stream.peek stream with
    (* if this is a binop, find its precedence *)
    | Some (Token.Kwd c) when Hashtbl.mem binop_precedence c ->
      let token_prec = precedence c in
      (* If this is a binop that binds at least as tightly as the current 
       * binop, consume it, otherwise we are done. *)
      if token_prec < expr_prec then lhs else begin
        (* eat the binop *)
        Stream.junk stream;
        (* parse the primary expression after the binary operator *)
        let rhs = parse_primary stream in
        (* okay, we know this is a binop *)
        let rhs =
          match Stream.peek stream with
            | Some (Token.Kwd c2) ->
              (* if BinOp binds less tightly with rhs than the
               * operator after rhs, let the pending operator take rhs
               * as its lhs *)
              let next_prec = precedence c2 in
              (* ie a + <- token_prec b * <- next_prec c *)
              if token_prec < next_prec
              then parse_bin_rhs (token_prec + 1) rhs stream
              else rhs
            | _ -> rhs
        in
        (* merge lhs/rhs *)
        let lhs = Ast.Binary (c, lhs, rhs) in
        parse_bin_rhs expr_prec lhs stream
      end
    | _ -> lhs

(* expression
 *    ::= primary binoprhs *)
and parse_expr = parser
| [< lhs=parse_primary ; stream >] ->
  parse_bin_rhs 0 lhs stream

(* prototype
 *    ::= id '(' id* ')' *)
let parse_prototype =
  (* this functions returns an array of id *)
  let rec parse_args accumulator = parser
    | [< 'Token.Ident id; e=parse_args (id::accumulator) >] -> e
    | [< >] -> accumulator
  in
  parser
  | [<
      'Token.Ident id;
      'Token.Kwd '(' ?? "expected '(' in prototype";
      args=parse_args [];
      'Token.Kwd ')' ?? "expected ')' in prototype"
    >] ->
      (* success *)
      Ast.Prototype (id, Array.of_list (List.rev args))

  | [< >] ->
    raise (Stream.Error "expected function name in prototype")


(* definition ::= 'def' prototype expression *)
let parse_definition = parser
  | [< 'Token.Def; p=parse_prototype; e=parse_expr >] ->
    Ast.Function (p, e)

(* toplevelexpr ::= expression *)
let parse_toplevel = parser
  | [< e=parse_expr >] ->
    (* Make an anoymous proto (function with random name and not arguments) *)
    let gen_passwd length =
      let gen () = match Random.int(26+26+10) with
          n when n < 26 -> int_of_char 'a' + n
        | n when n < 26 + 26 -> int_of_char 'A' + n - 26
        | n -> int_of_char '0' + n - 26 - 26 in
      let gen _ = String.make 1 (char_of_int(gen ())) in
      "anonyme_fun_" ^ String.concat "" (Array.to_list (Array.init length gen))
    in

    Ast.Function (Ast.Prototype (gen_passwd 5, [||]), e)

(* external ::= 'extern' prototype *)
let parse_extern = parser
  | [< 'Token.Extern; e=parse_prototype >] ->
    e

