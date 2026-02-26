(module

  ;; ===== Imports depuis le module OCaml "ono" =====
  (import "ono" "random_i32"   (func $random_i32   (result i32)))
  (import "ono" "print_cell"   (func $print_cell   (param i32)))
  (import "ono" "newline"      (func $newline))
  (import "ono" "clear_screen" (func $clear_screen))
  (import "ono" "sleep"        (func $sleep        (param f32)))
  (import "ono" "get_steps" (func $get_steps (result i32)))

  ;; ===== Mémoire =====
  (memory (export "memory") 1)

  ;; ===== Dimensions et offsets =====
  (global $w              i32       (i32.const 90))
  (global $h              i32       (i32.const 50))
  (global $size           i32       (i32.const 4500))   ;; w * h
  (global $current_offset (mut i32) (i32.const 0))
  (global $next_offset    (mut i32) (i32.const 4500))

  ;; ===== index(i, j) = current_offset + i * w + j =====
  (func $index (param $i i32) (param $j i32) (result i32)
    (i32.add
      (global.get $current_offset)
      (i32.add
        (i32.mul (local.get $i) (global.get $w))
        (local.get $j)
      )
    )
  )

  ;; ===== is_alive : retourne 0 si hors limites =====
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
        (i32.load8_u (call $index (local.get $i) (local.get $j)))
      )
    )
  )

  ;; ===== Compte les 8 voisins vivants =====
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

  ;; ===== Swap des buffers =====
  (func $swap_buffers
    (local $temp i32)
    (local.set $temp (global.get $current_offset))
    (global.set $current_offset (global.get $next_offset))
    (global.set $next_offset (local.get $temp))
  )

  ;; ===== Une étape du jeu de la vie =====
  (func $step
    (local $i i32)
    (local $j i32)
    (local $idx i32)
    (local $alive i32)
    (local $neigh i32)

    (local.set $i (i32.const 0))
    (block $outer_exit
      (loop $outer
        (br_if $outer_exit (i32.ge_s (local.get $i) (global.get $h)))

        (local.set $j (i32.const 0))
        (block $inner_exit
          (loop $inner
            (br_if $inner_exit (i32.ge_s (local.get $j) (global.get $w)))

            (local.set $idx (call $index (local.get $i) (local.get $j)))

            (local.set $alive (i32.load8_u (local.get $idx)))

            (local.set $neigh
              (call $count_alive_neighbours (local.get $i) (local.get $j))
            )

            ;; Règles du jeu de la vie
            (local.set $alive
              (if (result i32)
                  (local.get $alive)
                (then
                  (i32.or
                    (i32.eq (local.get $neigh) (i32.const 2))
                    (i32.eq (local.get $neigh) (i32.const 3))
                  )
                )
                (else
                  (i32.eq (local.get $neigh) (i32.const 3))
                )
              )
            )

            ;; Petite chance d'apparition spontanée (1/10000)
            (if
            (i32.eq (i32.rem_u (call $random_i32) (i32.const 10000)) (i32.const 0))
              (then (local.set $alive (i32.const 1)))
            )

            ;; Écriture dans le buffer suivant
            (i32.store8
              (i32.add
                (global.get $next_offset)
                (i32.sub (local.get $idx) (global.get $current_offset))
              )
              (local.get $alive)
            )

            (local.set $j (i32.add (local.get $j) (i32.const 1)))
            (br $inner)
          )
        )

        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $outer)
      )
    )

    (call $swap_buffers)
  )

  ;; ===== Initialisation aléatoire (~10% de cellules vivantes) =====
  (func $init_grid
    (local $i i32)
    (local $j i32)

    (local.set $i (i32.const 0))
    (block $outer_exit
      (loop $outer
        (br_if $outer_exit (i32.ge_s (local.get $i) (global.get $h)))

        (local.set $j (i32.const 0))
        (block $inner_exit
          (loop $inner
            (br_if $inner_exit (i32.ge_s (local.get $j) (global.get $w)))

            ;; vivante si random_i32() mod 100 > 90
            (i32.store8
              (call $index (local.get $i) (local.get $j))
              (i32.gt_s
                (i32.rem_u (call $random_i32) (i32.const 100))
                (i32.const 90)
              )
            )

            (local.set $j (i32.add (local.get $j) (i32.const 1)))
            (br $inner)
          )
        )

        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $outer)
      )
    )
  )

  ;; ===== Affichage de la grille =====
  (func $print_grid
    (local $i i32)
    (local $j i32)

    (local.set $i (i32.const 0))
    (block $outer_exit
      (loop $outer
        (br_if $outer_exit (i32.ge_s (local.get $i) (global.get $h)))

        (local.set $j (i32.const 0))
        (block $inner_exit
          (loop $inner
            (br_if $inner_exit (i32.ge_s (local.get $j) (global.get $w)))

            (call $print_cell
              (i32.load8_u (call $index (local.get $i) (local.get $j)))
            )

            (local.set $j (i32.add (local.get $j) (i32.const 1)))
            (br $inner)
          )
        )

        (call $newline)
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $outer)
      )
    )

    (call $clear_screen)
  )

  ;; ===== Boucle principale =====
  (func $main
    (local $steps i32)
    (local $i i32)

    (call $init_grid)

    ;; récupère le nombre d'étapes (-1 = infini)
    (local.set $steps (call $get_steps))
    (local.set $i (i32.const 0))

    (block $exit
     
      (loop $loop
        ;; si steps != -1 et i >= steps, on sort
        (br_if $exit
          (i32.and
            (i32.ne (local.get $steps) (i32.const -1))
            (i32.ge_s (local.get $i) (local.get $steps))
          )
        )
        (call $print_grid)
        (call $step)
        (call $sleep (f32.const 0.05))

        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $loop)
      )
    )
  )

  (start $main)
)
