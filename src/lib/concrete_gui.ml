open Raylib

let numRows = 10
let numCols = 10

let draw_grid ()=
  let w = get_screen_width () in
  let h = get_screen_height () in
  let cellw = w/numCols in
  let cellh = h/numRows in
  List.init (numCols + 1) (fun i -> i * cellw)
  |> List.iter (fun x -> draw_line x 0 x h Color.black);
  List.init (numRows + 1) (fun j -> j * cellh)
  |> List.iter (fun y -> draw_line 0 y w y Color.black)

let run () = 
  init_window 600 600 "test";
  set_window_state [ConfigFlags.Window_resizable];
  while not (window_should_close ()) do
    begin_drawing ();
    clear_background Color.raywhite;
    draw_grid ();
    draw_rectangle 0 0 10 10 Color.red;
    end_drawing ();
  done;
  close_window();
  Ok()
