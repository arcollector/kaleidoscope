type token =
  (* commands *)
  | Def | Extern
  (* primary *)
  | Ident of string | Number of float
  (* unknown *)
  | Kwd of char
  (* control *)
  | If | Then | Else
  | For | In
  (* operators *)
  | Binary | Unary
  (* var definiton *)
  | Var
