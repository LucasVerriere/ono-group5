(module

  (func $i32_symbol (import "ono" "i32_symbol") (result i32))
  (func $print_i32  (import "ono" "print_i32")  (param i32))
  (func $read_i32 (import "ono" "read_i32") (result i32))

  (memory (export "memory") 1)

  (global $w              (mut i32) (i32.const 5))
  (global $h              (mut i32) (i32.const 5))
  (global $size           (mut i32) (i32.const 25))
  (global $current_offset (mut i32) (i32.const 0))
  (global $next_offset    (mut i32) (i32.const 25))

  ;; cellule cible
  (global $TARGET_I i32 (i32.const 1))
  (global $TARGET_I_2 i32 (i32.const 3))
  (global $TARGET_J i32 (i32.const 1))
  (global $TARGET_J_2 i32 (i32.const 2))

  (global $NUMBER_OF_ALIVE_CELLS i32 (i32.const 6))

  ;; ========================== GAME OF LIFE ======================================

  (func $index (param $i i32) (param $j i32) (result i32)
    (i32.add
      (global.get $current_offset)
      (i32.add
        (i32.mul (local.get $i) (global.get $w))
        (local.get $j)
      )
    )
  )

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

  (func $count_alive_neighbours (param $i i32) (param $j i32) (result i32)
    (call $is_alive (i32.sub (local.get $i) (i32.const 1)) (i32.sub (local.get $j) (i32.const 1)))
    (call $is_alive (i32.sub (local.get $i) (i32.const 1)) (local.get $j))
    (call $is_alive (i32.sub (local.get $i) (i32.const 1)) (i32.add (local.get $j) (i32.const 1)))
    (call $is_alive (local.get $i) (i32.sub (local.get $j) (i32.const 1)))
    (call $is_alive (local.get $i) (i32.add (local.get $j) (i32.const 1)))
    (call $is_alive (i32.add (local.get $i) (i32.const 1)) (i32.sub (local.get $j) (i32.const 1)))
    (call $is_alive (i32.add (local.get $i) (i32.const 1)) (local.get $j))
    (call $is_alive (i32.add (local.get $i) (i32.const 1)) (i32.add (local.get $j) (i32.const 1)))
    i32.add
    i32.add
    i32.add
    i32.add
    i32.add
    i32.add
    i32.add
  )

  (func $swap_buffers
    (local $temp i32)
    (local.set $temp (global.get $current_offset))
    (global.set $current_offset (global.get $next_offset))
    (global.set $next_offset (local.get $temp))
  )

  ;; identique à game_of_life.wat sauf sans random_i32 et optimisation d'un if avec une condition symbolique 
  (func $step
    (local $i i32)
    (local $j i32)
    (local $idx i32)
    (local $alive i32)
    (local $neigh i32)

    (local.set $i (i32.const 0))
    (block $oi
      (loop $li
        (br_if $oi (i32.ge_s (local.get $i) (global.get $h)))
        (local.set $j (i32.const 0))
        (block $oj
          (loop $lj
            (br_if $oj (i32.ge_s (local.get $j) (global.get $w)))

            (local.set $idx   (call $index (local.get $i) (local.get $j)))
            (local.set $alive (i32.load8_u (local.get $idx)))
            (local.set $neigh (call $count_alive_neighbours (local.get $i) (local.get $j)))

            (local.set $alive
              (i32.or
                (i32.eq (local.get $neigh) (i32.const 3))
                (i32.and
                  (local.get $alive)
                  (i32.eq (local.get $neigh) (i32.const 2))
                )
              )
            )

            (i32.store8
              (i32.add
                (global.get $next_offset)
                (i32.sub (local.get $idx) (global.get $current_offset))
              )
              (local.get $alive)
            )

            (local.set $j (i32.add (local.get $j) (i32.const 1)))
            (br $lj)
          )
        )
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $li)
      )
    )

    (call $swap_buffers)
  )

  (func $print_grid
    (local $i i32)
    (local $j i32)

    (local.set $i (i32.const 0))
    (block $oi
      (loop $li
        (br_if $oi (i32.ge_s (local.get $i) (global.get $h)))
        (local.set $j (i32.const 0))
        (block $oj
          (loop $lj
            (br_if $oj (i32.ge_s (local.get $j) (global.get $w)))
            (call $print_i32 (i32.load8_u (call $index (local.get $i) (local.get $j))))
            (local.set $j (i32.add (local.get $j) (i32.const 1)))
            (br $lj)
          )
        )
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $li)
      )
    )
  )


  ;; ==============================================================================


  (func $constraint_1 (result i32)
    (call $is_alive (global.get $TARGET_I) (global.get $TARGET_J))
  )

  (func $constraint_2 (result i32)
    (i32.eqz (call $is_alive (global.get $TARGET_I) (global.get $TARGET_J)))
  )

  ;; Au tour suivant, il y a exactement $NUMBER_OF_ALIVE_CELLS cellules vivantes 
  (func $constraint_N_alive_cells (result i32)
    (local $count i32)
    (local $i i32)
    (local $j i32)

    (local.set $count (i32.const 0))
    (local.set $i (i32.const 0))

    (block $oi
      (loop $li
        (br_if $oi (i32.ge_s (local.get $i) (global.get $h)))

        (local.set $j (i32.const 0))

        (block $oj
          (loop $lj
            (br_if $oj (i32.ge_s (local.get $j) (global.get $w)))

            ;; if (is_alive(i, j)) count++
            (local.set $count
              (i32.add
                (local.get $count)
                (call $is_alive (local.get $i) (local.get $j))
              )
            )

            (local.set $j (i32.add (local.get $j) (i32.const 1)))
            (br $lj)
          )
        )

        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $li)
      )
    )

    (i32.eq (local.get $count) (global.get $NUMBER_OF_ALIVE_CELLS))
  )

  (func $constraint_3 (result i32)
    (local $i i32)
    (local $j i32)
    (local $result i32)

    (local.set $result (i32.const 0))
    (local.set $i (i32.const 0))

    (block $oi
      (loop $li
        (br_if $oi (i32.ge_s (local.get $i) (global.get $h)))
        (local.set $j (i32.const 0))
        (block $oj
          (loop $lj
            (br_if $oj (i32.ge_s (local.get $j) (global.get $w)))

            (local.set $result
              (i32.or
                (local.get $result)
                (call $is_alive (local.get $i) (local.get $j))
              )
            )

            (local.set $j (i32.add (local.get $j) (i32.const 1)))
            (br $lj)
          )
        )
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $li)
      )
    )

    (local.get $result)
  )

  (func $constraint_4 (result i32)
    (local $i i32)
    (local $j i32)
    (local $result i32)

    (local.set $result (i32.const 1))
    (local.set $i (i32.const 0))

    (block $oi
      (loop $li
        (br_if $oi (i32.ge_s (local.get $i) (global.get $h)))
        (local.set $j (i32.const 0))
        (block $oj
          (loop $lj
            (br_if $oj (i32.ge_s (local.get $j) (global.get $w)))

            (local.set $result
              (i32.and
                (local.get $result)
                (call $is_alive (local.get $i) (local.get $j))
              )
            )

            (local.set $j (i32.add (local.get $j) (i32.const 1)))
            (br $lj)
          )
        )
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $li)
      )
    )

    (local.get $result)
  )

  (func $constraint_5 (result i32)
    (local $i i32)
    (local $j i32)
    (local $result i32)

    (local.set $result (i32.const 1))
    (local.set $i (i32.const 0))

    (block $oi
      (loop $li
        (br_if $oi (i32.ge_s (local.get $i) (global.get $h)))
        (local.set $j (i32.const 0))
        (block $oj
          (loop $lj
            (br_if $oj (i32.ge_s (local.get $j) (global.get $w)))

            (local.set $result
              (i32.and
                (local.get $result)
                (i32.eqz (call $is_alive (local.get $i) (local.get $j)))
              )
            )

            (local.set $j (i32.add (local.get $j) (i32.const 1)))
            (br $lj)
          )
        )
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $li)
      )
    )

    (local.get $result)
  )

  (func $constraint_6 (result i32)
    (local $j i32)
    (local $result i32)

    (local.set $result (i32.const 1))
    (local.set $j (global.get $TARGET_J))

    (block $exit
      (loop $loop
        (br_if $exit (i32.gt_s (local.get $j) (global.get $TARGET_J_2)))

        (local.set $result
          (i32.and
            (local.get $result)
            (call $is_alive (global.get $TARGET_I) (local.get $j))
          )
        )

        (local.set $j (i32.add (local.get $j) (i32.const 1)))
        (br $loop)
      )
    )

    (local.get $result)
  )

  (func $constraint_7 (result i32)
    (local $i i32)
    (local $result i32)

    (local.set $result (i32.const 1))
    (local.set $i (global.get $TARGET_I))

    (block $exit
      (loop $loop
        (br_if $exit (i32.gt_s (local.get $i) (global.get $TARGET_I_2)))

        (local.set $result
          (i32.and
            (local.get $result)
            (call $is_alive (local.get $i) (global.get $TARGET_J))
          )
        )

        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $loop)
      )
    )

    (local.get $result)
  )

  ;; max(val, min_bound)
  (func $clamp_min (param $val i32) (param $min_bound i32) (result i32)

    ;; if sur des valeurs qui ne sont pas symbolique, donc pas de problème de performance
    (if (result i32) (i32.lt_s (local.get $val) (local.get $min_bound))
      (then (local.get $min_bound))
      (else (local.get $val))
    )
  )

  ;; min(val, max_bound)
  (func $clamp_max (param $val i32) (param $max_bound i32) (result i32)

    ;; if sur des valeurs qui ne sont pas symbolique, donc pas de problème de performance 
    (if (result i32) (i32.gt_s (local.get $val) (local.get $max_bound))
      (then (local.get $max_bound))
      (else (local.get $val))
    )
  )

  ;; symbolise toutes les cellules du rectangle [i_min, i_max] x [j_min, j_max]
  (func $init_rectangle_as_symbols 
    (param $i_min i32) (param $i_max i32)
    (param $j_min i32) (param $j_max i32)
    (local $i i32)
    (local $j i32)
    (local $sym i32)

    ;; pour rester dans les bornes de la grille
    (local.set $i_min (call $clamp_min (local.get $i_min) (i32.const 0)))
    (local.set $i_max (call $clamp_max (local.get $i_max) (i32.sub (global.get $h) (i32.const 1))))
    (local.set $j_min (call $clamp_min (local.get $j_min) (i32.const 0)))
    (local.set $j_max (call $clamp_max (local.get $j_max) (i32.sub (global.get $w) (i32.const 1))))

    (local.set $i (local.get $i_min))
    (block $oi (loop $li
      (br_if $oi (i32.gt_s (local.get $i) (local.get $i_max)))

      (local.set $j (local.get $j_min))
      (block $oj (loop $lj
        (br_if $oj (i32.gt_s (local.get $j) (local.get $j_max)))

        (local.set $sym (i32.and (call $i32_symbol) (i32.const 1)))
        (i32.store8 (call $index (local.get $i) (local.get $j)) (local.get $sym))

        (local.set $j (i32.add (local.get $j) (i32.const 1)))
        (br $lj)
      ))

      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $li)
    ))
  )

  (func $init_neighbors_as_symbols
    (call $init_rectangle_as_symbols
      (i32.sub (global.get $TARGET_I) (i32.const 1))
      (i32.add (global.get $TARGET_I) (i32.const 1))
      (i32.sub (global.get $TARGET_J) (i32.const 1))
      (i32.add (global.get $TARGET_J) (i32.const 1))
    )
  )

  (func $init_configuration_for_constraint_1_or_2
    (call $init_neighbors_as_symbols)

    (call $step)
  )

  (func $init_whole_grid_as_symbols
    (call $init_rectangle_as_symbols
      (i32.const 0)
      (i32.sub (global.get $h) (i32.const 1))
      (i32.const 0)
      (i32.sub (global.get $w) (i32.const 1))
    )
  )

  (func $init_configuration_for_constraint_3_to_5
    (call $init_whole_grid_as_symbols)

    (call $step)
  )

  ;; initialisation de la grille : seules le rectangle [TARGET_I-1, TARGET_I+1] x [TARGET_J-1, TARGET_J_2+1] est symbolique
  (func $init_full_line_as_symbols
    (call $init_rectangle_as_symbols
      (i32.sub (global.get $TARGET_I)   (i32.const 1))
      (i32.add (global.get $TARGET_I)   (i32.const 1))
      (i32.sub (global.get $TARGET_J)   (i32.const 1))
      (i32.add (global.get $TARGET_J_2) (i32.const 1))
    )
  )

  (func $init_configuration_for_full_line
    (call $init_full_line_as_symbols)
    (call $step)
  )

  (func $init_full_column_as_symbols
    (call $init_rectangle_as_symbols
      (i32.sub (global.get $TARGET_I)   (i32.const 1))
      (i32.add (global.get $TARGET_I_2) (i32.const 1))
      (i32.sub (global.get $TARGET_J)   (i32.const 1))
      (i32.add (global.get $TARGET_J)   (i32.const 1))
    )
  )

  (func $init_configuration_for_full_column
    (call $init_full_column_as_symbols)
    (call $step)
  )

  (func $print_initial_grid
    (call $swap_buffers)
    (call $print_i32 (global.get $w))
    (call $print_i32 (global.get $h))
    (call $print_grid)
  )

  (func $main

    (local $constraint_to_calculate i32)
    (local.set $constraint_to_calculate (call $read_i32))

    (if (i32.eq (local.get $constraint_to_calculate) (i32.const 1)) 
      (then 
        (call $init_configuration_for_constraint_1_or_2)
        (if (call $constraint_1) (then unreachable))
      )
    )
        
    (if (i32.eq (local.get $constraint_to_calculate) (i32.const 2)) 
      (then 
        (call $init_configuration_for_constraint_1_or_2)
        (if (call $constraint_2) (then unreachable))
      )
    )

    (if (i32.eq (local.get $constraint_to_calculate) (i32.const 99)) 
      (then 
        (call $init_configuration_for_constraint_3_to_5)
        (if (call $constraint_N_alive_cells) (then unreachable))
      )
    )

    (if (i32.eq (local.get $constraint_to_calculate) (i32.const 3)) 
      (then 
        (call $init_configuration_for_constraint_3_to_5)
        (if (call $constraint_3) (then unreachable))
      )
    )

    (if (i32.eq (local.get $constraint_to_calculate) (i32.const 4)) 
      (then 
        (call $init_configuration_for_constraint_3_to_5)
        (if (call $constraint_4) (then unreachable))
      )
    )

    (if (i32.eq (local.get $constraint_to_calculate) (i32.const 5)) 
      (then 
        (call $init_configuration_for_constraint_3_to_5)
        (if (call $constraint_5) (then unreachable))
      )
    )

    (if (i32.eq (local.get $constraint_to_calculate) (i32.const 6)) 
      (then 
        (call $init_configuration_for_full_line)
        (if (call $constraint_6) (then unreachable))
      )
    )

    (if (i32.eq (local.get $constraint_to_calculate) (i32.const 7)) 
      (then 
        (call $init_configuration_for_full_column)
        (if (call $constraint_7) (then unreachable))
      )
    )

    (call $print_initial_grid)
    
  )

  (start $main)
)