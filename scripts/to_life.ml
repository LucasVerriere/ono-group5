(* scripts/to_life.ml
   Usage:
     ocaml -I +str str.cma to_life.ml W H

   Lit le bloc "model { ... }" depuis stdin et produit un .life sur stdout.
   La grille entière est supposée symbolisée par constraints.wat.
*)

let () =
  prerr_string "Entrez le numéro de la contrainte : ";
  flush stderr;
  if Array.length Sys.argv <> 3 then begin
    prerr_endline "Usage: to_life W H";
    exit 1
  end;
  let w = int_of_string Sys.argv.(1) in
  let h = int_of_string Sys.argv.(2) in

  (* lit stdin et extrait les valeurs des symboles du bloc model *)
  let buf = Buffer.create 4096 in
  (try while true do Buffer.add_channel buf stdin 4096 done
   with End_of_file -> ());
  let input = Buffer.contents buf in

  let re = Str.regexp "symbol[ \t]+symbol_\\([0-9]+\\)[ \t]+i32[ \t]+\\([0-9]+\\)" in
  let model = Hashtbl.create 64 in
  let pos = ref 0 in
  (try
    while true do
      let _ = Str.search_forward re input !pos in
      let idx = int_of_string (Str.matched_group 1 input) in
      let value = int_of_string (Str.matched_group 2 input) in
      Hashtbl.replace model idx (value land 1);
      pos := Str.match_end ()
    done
  with Not_found -> ());

  if Hashtbl.length model = 0 then begin
    let is_unsat =
      try
        let _ = Str.search_forward (Str.regexp "All OK!") input 0 in true
      with Not_found -> false
    in
    if is_unsat then
      prerr_endline "La contrainte est insatisfiable : Owi n'a trouvé aucune configuration valide."
    else
      prerr_endline "Erreur : aucun symbole trouvé dans l'entrée.";
    exit 1
  end;

  (* place les symboles dans la grille (parcours lexicographique) *)
  let grid = Array.make_matrix h w 0 in
  let sym_idx = ref 0 in
  for i = 0 to h - 1 do
    for j = 0 to w - 1 do
      let v = try Hashtbl.find model !sym_idx with Not_found -> 0 in
      grid.(i).(j) <- v;
      incr sym_idx
    done
  done;

  Printf.printf "%d %d\n" w h;
  for i = 0 to h - 1 do
    for j = 0 to w - 1 do
      print_char (if grid.(i).(j) = 1 then 'X' else '.')
    done;
    print_newline ()
  done