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

let get_tail () : (Kdo.Concrete.I32.t, _) Result.t =
  Ok (Kdo.Concrete.I32.of_int 0)
(* 0 => afficher toutes les étapes *)

let read_int () : (Kdo.Concrete.I32.t, _) Result.t =
  try
    let line = read_line () in
    let value = Int32.of_string line in
    Ok (Kdo.Concrete.I32.of_int32 value)
  with _ -> Ok (Kdo.Concrete.I32.of_int32 0l)

(* Lecture du fichier de configuration *)
let config_cells : int array ref = ref [||]
let config_index = ref 0
let config_w = ref 0
let config_h = ref 0
let steps = ref 0
let has_config = ref false

let load_config_file path =
  let ic = open_in path in
  let line = input_line ic in
  let parts = String.split_on_char ' ' (String.trim line) in
  (match parts with
  | [ w_s; h_s ] ->
      config_w := int_of_string w_s;
      config_h := int_of_string h_s
  | _ -> failwith "Format invalide : première ligne doit être 'w h'");
  let cells = Buffer.create 256 in
  (try
     while true do
       let row = input_line ic in
       String.iter (fun c -> Buffer.add_char cells c) (String.trim row)
     done
   with End_of_file -> ());
  close_in ic;
  config_cells :=
    Array.init (Buffer.length cells) (fun i ->
        if Buffer.nth cells i = 'X' then 1 else 0);
  config_index := 0;
  has_config := true

(* Appelé depuis Wasm pour savoir si un fichier a été fourni *)
let has_config_file () : (Kdo.Concrete.I32.t, _) Result.t =
  Ok (Kdo.Concrete.I32.of_int (if !has_config then 1 else 0))

(* Appelé depuis Wasm pour lire la largeur du fichier *)
let config_get_w () : (Kdo.Concrete.I32.t, _) Result.t =
  Ok (Kdo.Concrete.I32.of_int !config_w)

(* Appelé depuis Wasm pour lire la hauteur du fichier *)
let config_get_h () : (Kdo.Concrete.I32.t, _) Result.t =
  Ok (Kdo.Concrete.I32.of_int !config_h)

let get_steps () : (Kdo.Concrete.I32.t, _) Result.t =
  Ok (Kdo.Concrete.I32.of_int !steps)
(* mettre -1 pour mode interactif infini *)

(* Appelé depuis Wasm pour lire cellule par cellule *)
let config_next_cell () : (Kdo.Concrete.I32.t, _) Result.t =
  let cells = !config_cells in
  let idx = !config_index in
  if idx >= Array.length cells then Ok (Kdo.Concrete.I32.of_int 0)
  else begin
    incr config_index;
    Ok (Kdo.Concrete.I32.of_int cells.(idx))
  end

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
      ("has_config_file", Extern_func (unit ^->. i32, has_config_file));
      ("config_get_w", Extern_func (unit ^->. i32, config_get_w));
      ("config_get_h", Extern_func (unit ^->. i32, config_get_h));
      ("config_next_cell", Extern_func (unit ^->. i32, config_next_cell));
    ]
  in
  {
    Kdo.Extern.Module.functions;
    func_type = Kdo.Concrete.Extern_func.extern_type;
  }
