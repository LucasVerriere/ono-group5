(* The `ono concrete` command. *)

open Cmdliner
open Ono_cli

let info = Cmd.info "concrete" ~exits

(* Nouvel argument --file *)
let config_file =
  let doc = "Initial configuration file (.life format)." in
  Arg.(
    value
    & opt (some existing_file_conv) None (info [ "file" ] ~doc ~docv:"CONFIG"))

let term =
  let open Term.Syntax in
  let+ () = setup_log
  and+ source_file = source_file
  and+ seed = seed
  and+ config_file = config_file 
  and+ steps = steps in
  Ono.Concrete_ono_module.steps := (match steps with Some s -> s | None -> 0);
  (* Charger le fichier de config si fourni *)
  (match seed with Some s -> Random.init s | None -> Random.self_init ());
  (match config_file with
  | Some path -> Ono.Concrete_ono_module.load_config_file (Fpath.to_string path)
  | None -> ());
  Ono.Concrete_driver.run ~source_file |> function
  | Ok () -> Ok ()
  | Error e -> Error (`Msg (Kdo.R.err_to_string e))

let cmd : Ono_cli.outcome Cmd.t = Cmd.v info term
