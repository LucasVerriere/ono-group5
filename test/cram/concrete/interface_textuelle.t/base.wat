(module
  ;; IMPORTS - fonctions OCaml
  (func $print_cell (import "ono" "print_cell") (param i32))
  (func $newline (import "ono" "newline"))
  (func $clear_screen (import "ono" "clear_screen"))
  ;;(func $sleep (import "ono" "sleep") (param f32))
  (func $random_i32 (import "ono" "random_i32") (result i32))
  (func $read_int (import "ono" "read_int") (result i32))

  ;; VARIABLES GLOBALES
  (global $w (mut i32) (i32.const 90))
  (global $h (mut i32) (i32.const 50))
  (global $size (mut i32) (i32.const 4500))
  (global $next_offset (mut i32) (i32.const 4500))

  ;; MÉMOIRE - stocke l'état du jeu
  ;; Adresse 0: grille actuelle (width * height bytes)
  ;; Adresse next_offset: grille suivante (width * height bytes)
  (memory (export "memory") 10)

  ;; ==================== CONVERSIONS 2D ↔ 1D ====================
  ;; Convertir coordonnées 2D → 1D
  ;; index = i * w + j
  (func $coord_2d_to_1d (param $i i32) (param $j i32) (result i32)
    (i32.add
      (i32.mul (local.get $i) (global.get $w))
      (local.get $j)
    )
  )

  ;; ==================== ACCESSEURS CELLULES ====================
  ;; Lire une cellule (0 = morte, 1 = vivante)
  ;; Retourne 0 si hors limites
  (func $is_alive (param $i i32) (param $j i32) (result i32)
    (if (result i32)
        (i32.or
          (i32.lt_s (local.get $i) (i32.const 0))
          (i32.or
            (i32.lt_s (local.get $j) (i32.const 0))
            (i32.or
              (i32.ge_s (local.get $i) (global.get $h))
              (i32.ge_s (local.get $j) (global.get $w))
            )
          )
        )
      (then (i32.const 0))
      (else
        (i32.load8_u
          (call $coord_2d_to_1d (local.get $i) (local.get $j))
        )
      )
    )
  )

  ;; Écrire une cellule
  (func $set_cell (param $i i32) (param $j i32) (param $value i32)
    (local $addr i32)
    (local.set $addr (call $coord_2d_to_1d (local.get $i) (local.get $j)))
    (i32.store8 (local.get $addr) (local.get $value))
  )

  ;; Lire une cellule dans la grille "suivante"
  (func $get_next_cell (param $i i32) (param $j i32) (result i32)
    (local $addr i32)
    (local.set $addr
      (i32.add
        (call $coord_2d_to_1d (local.get $i) (local.get $j))
        (global.get $next_offset)
      )
    )
    (i32.load8_u (local.get $addr))
  )

  ;; Écrire une cellule dans la grille "suivante"
  (func $set_next_cell (param $i i32) (param $j i32) (param $value i32)
    (local $addr i32)
    (local.set $addr
      (i32.add
        (call $coord_2d_to_1d (local.get $i) (local.get $j))
        (global.get $next_offset)
      )
    )
    (i32.store8 (local.get $addr) (local.get $value))
  )

  ;; ==================== VOISINS ====================
  ;; Compter les voisins vivants (8 directions)
  (func $count_alive_neighbours (param $i i32) (param $j i32) (result i32)
    (i32.add
      (call $is_alive (i32.sub (local.get $i) (i32.const 1)) (i32.sub (local.get $j) (i32.const 1)))
      (i32.add
        (call $is_alive (i32.sub (local.get $i) (i32.const 1)) (local.get $j))
        (i32.add
          (call $is_alive (i32.sub (local.get $i) (i32.const 1)) (i32.add (local.get $j) (i32.const 1)))
          (i32.add
            (call $is_alive (local.get $i) (i32.sub (local.get $j) (i32.const 1)))
            (i32.add
              (call $is_alive (local.get $i) (i32.add (local.get $j) (i32.const 1)))
              (i32.add
                (call $is_alive (i32.add (local.get $i) (i32.const 1)) (i32.sub (local.get $j) (i32.const 1)))
                (i32.add
                  (call $is_alive (i32.add (local.get $i) (i32.const 1)) (local.get $j))
                  (call $is_alive (i32.add (local.get $i) (i32.const 1)) (i32.add (local.get $j) (i32.const 1)))
                )
              )
            )
          )
        )
      )
    )
  )

  ;; ==================== INITIALISATION ====================
  ;; Initialiser la grille avec des valeurs aléatoires (10% vivantes)
  (func $init_grid
    (local $i i32)
    (local $j i32)
    (local $rand i32)

    (local.set $i (i32.const 0))
    (block $break_i
      (loop $loop_i
        (br_if $break_i (i32.ge_s (local.get $i) (global.get $h)))

        (local.set $j (i32.const 0))
        (block $break_j
          (loop $loop_j
            (br_if $break_j (i32.ge_s (local.get $j) (global.get $w)))

            ;; 10% de chance d'être vivant
            (local.set $rand (call $random_i32))
            (if (i32.lt_u (i32.rem_u (local.get $rand) (i32.const 100)) (i32.const 10))
              (then (call $set_cell (local.get $i) (local.get $j) (i32.const 1)))
              (else (call $set_cell (local.get $i) (local.get $j) (i32.const 0)))
            )

            (local.set $j (i32.add (local.get $j) (i32.const 1)))
            (br $loop_j)
          )
        )

        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $loop_i)
      )
    )
  )

  ;; ==================== SIMULATION ====================
  ;; Effectuer une étape du jeu de la vie
  (func $step
    (local $i i32)
    (local $j i32)
    (local $cell_alive i32)
    (local $neighbours i32)
    (local $should_live i32)

    ;; Calculer l'état suivant pour chaque cellule
    (local.set $i (i32.const 0))
    (block $break_i
      (loop $loop_i
        (br_if $break_i (i32.ge_s (local.get $i) (global.get $h)))

        (local.set $j (i32.const 0))
        (block $break_j
          (loop $loop_j
            (br_if $break_j (i32.ge_s (local.get $j) (global.get $w)))

            ;; Lire état actuel
            (local.set $cell_alive (call $is_alive (local.get $i) (local.get $j)))

            ;; Compter voisins
            (local.set $neighbours
              (call $count_alive_neighbours (local.get $i) (local.get $j))
            )

            ;; Appliquer règles du jeu de la vie
            (local.set $should_live (i32.const 0))

            (if (local.get $cell_alive)
              (then
                ;; Une cellule vivante survit si elle a 2 ou 3 voisins
                (if (i32.or
                  (i32.eq (local.get $neighbours) (i32.const 2))
                  (i32.eq (local.get $neighbours) (i32.const 3))
                )
                  (then (local.set $should_live (i32.const 1)))
                )
              )
              (else
                ;; Une cellule morte devient vivante si elle a exactement 3 voisins
                (if (i32.eq (local.get $neighbours) (i32.const 3))
                  (then (local.set $should_live (i32.const 1)))
                )
              )
            )

            ;; Très faible probabilité qu'une cellule apparaisse spontanément
            (if (i32.eq (i32.rem_u (call $random_i32) (i32.const 10000)) (i32.const 0))
              (then (local.set $should_live (i32.const 1)))
            )

            ;; Écrire dans la grille suivante
            (call $set_next_cell (local.get $i) (local.get $j) (local.get $should_live))

            (local.set $j (i32.add (local.get $j) (i32.const 1)))
            (br $loop_j)
          )
        )

        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $loop_i)
      )
    )

    ;; Copier la grille suivante dans la grille actuelle
    (local.set $i (i32.const 0))
    (block $break_copy_i
      (loop $loop_copy_i
        (br_if $break_copy_i (i32.ge_s (local.get $i) (global.get $h)))

        (local.set $j (i32.const 0))
        (block $break_copy_j
          (loop $loop_copy_j
            (br_if $break_copy_j (i32.ge_s (local.get $j) (global.get $w)))

            (call $set_cell
              (local.get $i)
              (local.get $j)
              (call $get_next_cell (local.get $i) (local.get $j))
            )

            (local.set $j (i32.add (local.get $j) (i32.const 1)))
            (br $loop_copy_j)
          )
        )

        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $loop_copy_i)
      )
    )
  )

  ;; ==================== AFFICHAGE ====================
  ;; Afficher la grille entière
  (func $print_grid
    (local $i i32)
    (local $j i32)
    (local $cell i32)

    (local.set $i (i32.const 0))
    (block $break_i
      (loop $loop_i
        (br_if $break_i (i32.ge_s (local.get $i) (global.get $h)))

        (local.set $j (i32.const 0))
        (block $break_j
          (loop $loop_j
            (br_if $break_j (i32.ge_s (local.get $j) (global.get $w)))

            ;; Lire et afficher cellule
            (local.set $cell (call $is_alive (local.get $i) (local.get $j)))
            (call $print_cell (local.get $cell))

            (local.set $j (i32.add (local.get $j) (i32.const 1)))
            (br $loop_j)
          )
        )

        ;; Fin de ligne
        (call $newline)
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $loop_i)
      )
    )
  )

  ;; ==================== PROGRAMME PRINCIPAL ====================
  ;; Boucle principale infinie
  (func $main
    ;; Initialiser la grille
    (call $init_grid)

    ;; Boucle infinie
    (block $break_loop
      (loop $loop
        ;; Afficher et effacer l'écran
        (call $clear_screen)
        (call $print_grid)

        ;; Pause pour voir le résultat
        ;;(call $sleep (f32.const 0.1))

        ;; Étape suivante
        (call $step)

        ;; Boucler
        (br $loop)
      )
    )
  )

  ;; Point d'entrée
  (start $main)
)