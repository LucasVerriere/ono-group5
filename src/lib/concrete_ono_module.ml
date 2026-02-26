type extern_func = Kdo.Concrete.Extern_func.extern_func

(* Buffer pour accumuler l'affichage avant de le rendre *)
let display_buffer = Buffer.create 10240

let print_i32 (n : Kdo.Concrete.I32.t) : (unit, _) Result.t =
  Logs.app (fun m -> m "%a" Kdo.Concrete.I32.pp n);
  Ok ()

let random_i32 () : (Kdo.Concrete.I32.t, _) Result.t =
  Ok (Kdo.Concrete.I32.of_int32 (Random.bits32 ()))

let print_i64 (n : Kdo.Concrete.I64.t) : (unit, _) Result.t =
  Logs.app (fun m -> m "%a" Kdo.Concrete.I64.pp n);
  Ok ()

(* Nouvelles fonctions pour le jeu de la Vie *)

let print_cell (cell : Kdo.Concrete.I32.t) : (unit, _) Result.t =
  let cell_int = Kdo.Concrete.I32.to_int cell in
  let symbol = if cell_int <> 0 then "🦊" else " " in
  Buffer.add_string display_buffer symbol;
  Ok ()

let newline () : (unit, _) Result.t =
  Buffer.add_char display_buffer '\n';
  Ok ()

let step_counter = ref 0

let clear_screen () : (unit, _) Result.t =
  (* Efface l'écran avec le code ANSI *)
  incr step_counter;
  Format.printf "\027[2J";
  Format.printf
    "================================================== Step n° %d \
     ==================================================\n"
    !step_counter;
  (* Affiche le contenu du buffer *)
  Format.printf "%s" (Buffer.contents display_buffer);
  Format.pp_print_flush Format.std_formatter ();
  (* Vide le buffer *)
  Buffer.clear display_buffer;
  Ok ()

let sleep (duration : Kdo.Concrete.F32.t) : (unit, _) Result.t =
  let seconds = Kdo.Concrete.F32.to_float duration in
  Unix.sleepf seconds;
  Ok ()

let get_steps () : (Kdo.Concrete.I32.t, _) Result.t =
  Ok (Kdo.Concrete.I32.of_int 5)
(* mettre -1 pour mode interactif infini *)

let get_tail () : (Kdo.Concrete.I32.t, _) Result.t =
  Ok (Kdo.Concrete.I32.of_int 0)
(* 0 => afficher toutes les étapes *)

let read_int () : (Kdo.Concrete.I32.t, _) Result.t =
  try
    let line = read_line () in
    let value = Int32.of_string line in
    Ok (Kdo.Concrete.I32.of_int32 value)
  with _ -> Ok (Kdo.Concrete.I32.of_int32 0l)

let m =
  let open Kdo.Concrete.Extern_func in
  let open Kdo.Concrete.Extern_func.Syntax in
  let functions =
    [
      ("print_i32", Extern_func (i32 ^->. unit, print_i32));
      ("print_i64", Extern_func (i64 ^->. unit, print_i64));
      ("random_i32", Extern_func (unit ^->. i32, random_i32));
      ("print_cell", Extern_func (i32 ^->. unit, print_cell));
      ("newline", Extern_func (unit ^->. unit, newline));
      ("clear_screen", Extern_func (unit ^->. unit, clear_screen));
      ("sleep", Extern_func (f32 ^->. unit, sleep));
      ("read_int", Extern_func (unit ^->. i32, read_int));
      ("get_steps", Extern_func (unit ^->. i32, get_steps));
      ("get_tail", Extern_func (unit ^->. i32, get_tail));
    ]
  in
  {
    Kdo.Extern.Module.functions;
    func_type = Kdo.Concrete.Extern_func.extern_type;
  }
