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
  (global $TARGET_I i32 (i32.const 2))
  (global $TARGET_J i32 (i32.const 2))

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

  ;; identique à game_of_life.wat sauf sans random_i32
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

            (local.set $idx   (call $index (local.get $i) (local.get $j)))
            (local.set $alive (i32.load8_u (local.get $idx)))
            (local.set $neigh (call $count_alive_neighbours (local.get $i) (local.get $j)))

            (local.set $alive
              (if (result i32) (local.get $alive)
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
            (call $print_i32 (i32.load8_u (call $index (local.get $i) (local.get $j))))
            (local.set $j (i32.add (local.get $j) (i32.const 1)))
            (br $inner)
          )
        )
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $outer)
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


  ;; initialisation de la grille : Seules les 9 cellules du voisinage de (TARGET_I, TARGET_J) sont symboliques
  (func $symbol_init_for_constraints_1_or_2 
    (local $i i32)
    (local $j i32)
    (local $sym i32)
    (local.set $i (i32.sub (global.get $TARGET_I) (i32.const 1)))
    (block $oi (loop $li
      (br_if $oi (i32.gt_s (local.get $i) (i32.add (global.get $TARGET_I) (i32.const 1))))
      (local.set $j (i32.sub (global.get $TARGET_J) (i32.const 1)))
      (block $oj (loop $lj
        (br_if $oj (i32.gt_s (local.get $j) (i32.add (global.get $TARGET_J) (i32.const 1))))
        (local.set $sym (i32.and (call $i32_symbol) (i32.const 1)))
        (i32.store8 (call $index (local.get $i) (local.get $j)) (local.get $sym))
        (local.set $j (i32.add (local.get $j) (i32.const 1)))
        (br $lj)
      ))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $li)
    ))
  )

  (func $init_configuration
    (call $symbol_init_for_constraints_1_or_2)

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
        (call $init_configuration)
        (if (call $constraint_1) (then unreachable))
      )
    )
        
    (if (i32.eq (local.get $constraint_to_calculate) (i32.const 2)) 
      (then 
        (call $init_configuration)
        (if (call $constraint_2) (then unreachable))
      )
    )

    (call $print_initial_grid)
    
  )

  (start $main)
)