(module
  (func $print_i32 (import "ono" "print_i32") (param i32))
  (memory (export "memory") 1)
  (global $w i32 (i32.const 10))
  (global $h i32 (i32.const 20))
  (global $size i32 (i32.const 200))
  (global $next_offset i32 (i32.const 200))

  ;; index = i * w + j
  (func $index (param $i i32) (param $j i32) (result i32)
    (i32.add
      (i32.mul (local.get $i) (global.get $w))
      (local.get $j)
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
        (i32.load8_u
          (call $index (local.get $i) (local.get $j))
        )
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


  (func $step

    (local $i i32)
    (local $j i32)
    (local $idx i32)
    (local $alive i32)
    (local $neigh i32)

    (local.set $i (i32.const 0))

    (block $outer_exit
      (loop $outer
        (br_if $outer_exit
          (i32.ge_s (local.get $i) (global.get $h))
        )

        (local.set $j (i32.const 0))

        (block $inner_exit
          (loop $inner
            (br_if $inner_exit
              (i32.ge_s (local.get $j) (global.get $w))
            )

            (local.set $idx
              (call $index (local.get $i) (local.get $j))
            )

            (local.set $alive
              (i32.load8_u (local.get $idx))
            )

            (local.set $neigh
              (call $count_alive_neighbours (local.get $i) (local.get $j))
            )

            ;; game of life rules
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

            ;; write to next buffer
            (i32.store8
              (i32.add (local.get $idx) (global.get $next_offset))
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
  )

  (func $set_alive (param $x i32) (param $y i32)
    (i32.store8
      (call $index (local.get $x) (local.get $y))
      (i32.const 1)
    )
  )

  (func $main
    (call $set_alive (i32.const 1) (i32.const 0))
    (call $set_alive (i32.const 2) (i32.const 1))
    (call $set_alive (i32.const 0) (i32.const 2))
    (call $set_alive (i32.const 1) (i32.const 2))
    (call $set_alive (i32.const 2) (i32.const 2))

    (call $step)

    (call $print_i32 (i32.load8_u (i32.add (global.get $next_offset) (call $index (i32.const 0) (i32.const 1)))))
    (call $print_i32 (i32.load8_u (i32.add (global.get $next_offset) (call $index (i32.const 2) (i32.const 1)))))
    (call $print_i32 (i32.load8_u (i32.add (global.get $next_offset) (call $index (i32.const 1) (i32.const 2)))))
    (call $print_i32 (i32.load8_u (i32.add (global.get $next_offset) (call $index (i32.const 2) (i32.const 2)))))
    (call $print_i32 (i32.load8_u (i32.add (global.get $next_offset) (call $index (i32.const 1) (i32.const 3)))))


  )
  (start $main)



)
