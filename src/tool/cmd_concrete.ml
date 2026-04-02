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
  and+ steps = steps 
  and+ use_graphical_window = use_graphical_window
  and+ sleep = sleep_duration_ms in

    Ono.Concrete_ono_module.steps := (match steps with Some s -> s | None -> Int.max_int);
    (match sleep with Some ms -> Ono.Concrete_ono_module.set_sleep_duration_ms ms | None -> ());
    (* Charger le fichier de config si fourni *)
    (match seed with Some s -> Random.init s | None -> Random.self_init ());
    (match config_file with
    | Some path -> (Ono.Concrete_ono_module.load_config_file (Fpath.to_string path); 
    if use_graphical_window then 
      (
        Ono.Concrete_gui.init ~nb_rows:!(Ono.Concrete_ono_module.config_h) ~nb_cols:!(Ono.Concrete_ono_module.config_w); 
        while not (Ono.Concrete_gui.w_should_close ()) do
          Ono.Concrete_gui.render ()
        done
      )
    )
    | None -> ());
    Ono.Concrete_driver.run ~source_file |> function
    | Ok () -> Ok ()
    | Error e -> Error (`Msg (Kdo.R.err_to_string e))
let cmd : Ono_cli.outcome Cmd.t = Cmd.v info term
