(* The `ono concrete` command. *)

open Cmdliner
open Ono_cli

let info = Cmd.info "concrete" ~exits

let term =
  let open Term.Syntax in
  let+ () = setup_log and+ source_file = source_file and+ seed = seed in
  Ono.Concrete_driver.run ~source_file ~seed |> function
  | Ok () -> Ok ()
  | Error e -> Error (`Msg (Kdo.R.err_to_string e))

let cmd : Ono_cli.outcome Cmd.t = Cmd.v info term
