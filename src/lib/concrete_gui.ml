open Raylib

type d = {
  mutable nb_rows : int;
  mutable nb_cols : int;
  cell_size : int;
  mutable grid : int array array;
  mutable initialised : bool;
}

let data:d = {
  nb_rows = 0;
  nb_cols = 0;
  cell_size = 20;
  grid = [||];
  initialised = false;
}

let init ~nb_rows ~nb_cols =
  data.nb_rows <- nb_rows;
  data.nb_cols <- nb_cols;
  data.grid <- Array.make_matrix nb_rows nb_cols 0;
  let width = (nb_cols * data.cell_size) in
  let height = (nb_rows * data.cell_size) in
  init_window width height "Game of Life";
  data.initialised <- true

let set_cell ~row ~col ~alive =
  if row >=0 && row < data.nb_rows && col>=0 && col < data.nb_cols then data.grid.(row).(col) <- if alive then 1 else 0

let draw_grid ()=
  let w = data.nb_cols * data.cell_size in
  let h = data.nb_rows * data.cell_size in
  let cols =  List.init (data.nb_cols + 1) (fun i -> i * data.cell_size) in
  let rows = List.init (data.nb_rows + 1) (fun j -> j * data.cell_size) in
  List.iter (fun x -> draw_line x 0 x h Color.black) cols;
  List.iter (fun y -> draw_line 0 y w y Color.black) rows

let draw_cells ()=
  Array.iteri (fun row_nb row_content ->
    Array.iteri (fun col_nb cell_val ->
      if cell_val <> 0 then
        draw_rectangle (col_nb*data.cell_size) (row_nb*data.cell_size) (data.cell_size) (data.cell_size) Color.black 
      ) row_content ) data.grid

let render ()=
  begin_drawing ();
  clear_background Color.raywhite;
  draw_grid ();
  draw_cells ();
  end_drawing ();

let w_should_close () =
  data.initialised && window_should_close ()

let close () =
  if data.initialised then begin
    close_window ();
    data.initialised <- false;
  end
