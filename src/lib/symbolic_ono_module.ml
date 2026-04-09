type extern_func = Kdo.Symbolic.Extern_func.extern_func

let print_i32 (n : Kdo.Symbolic.I32.t) : unit Kdo.Symbolic.Choice.t =
  Logs.app (fun m -> m "%a" Kdo.Symbolic.I32.pp n);
  Kdo.Symbolic.Choice.return ()

let i32_symbol () : Kdo.Symbolic.I32.t Kdo.Symbolic.Choice.t =
  Kdo.Symbolic.Choice.with_new_symbol (Smtml.Ty.Ty_bitv 32)
    Kdo.Symbolic.I32.symbol

let rec read_i32 () : Kdo.Symbolic.I32.t Kdo.Symbolic.Choice.t =
  try
    let value = read_int () in
    Kdo.Symbolic.Choice.return (Kdo.Symbolic.I32.of_int value)
  with Failure _ ->
    Printf.printf " pleaz enter a number\n  > ";
    Out_channel.flush Out_channel.stdout;
    read_i32 ()

let print_prompt () : unit Kdo.Symbolic.Choice.t =
  print_string "Entrez le numéro de la contrainte : ";
  Kdo.Symbolic.Choice.return ()

let print_header () : unit Kdo.Symbolic.Choice.t =
  Logs.app (fun m -> m "\n====== Degree 3 Polynomial Solver ======\n");
  Logs.app (fun m -> m "Solving: p(x) = a*x³ + b*x² + c*x + d = 0\n");
  Logs.app (fun m -> m "Enter coefficients a, b, c and d:");
  Kdo.Symbolic.Choice.return ()

let prompt () : unit Kdo.Symbolic.Choice.t =
  Printf.printf "> ";
  Out_channel.flush Out_channel.stdout;
  Kdo.Symbolic.Choice.return ()


let print_solutions () : unit Kdo.Symbolic.Choice.t =
  Logs.app (fun m -> m "\nSolutions are:\n");
  Kdo.Symbolic.Choice.return ()

let m =
  let open Kdo.Symbolic.Extern_func in
  let open Kdo.Symbolic.Extern_func.Syntax in
  let functions =
    [
      ("print_i32", Extern_func (i32 ^->. unit, print_i32));
      ("i32_symbol", Extern_func (unit ^->. i32, i32_symbol));
      ("read_i32", Extern_func (unit ^->. i32, read_i32));
      ("print_prompt", Extern_func (unit ^->. unit, print_prompt));
      ("print_header", Extern_func (unit ^->. unit, print_header));
      ("prompt", Extern_func (unit ^->. unit, prompt));
      ("print_solutions", Extern_func (unit ^->. unit, print_solutions));
    ]
  in
  {
    Kdo.Extern.Module.functions;
    func_type = Kdo.Symbolic.Extern_func.extern_type;
  }
