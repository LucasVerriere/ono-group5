(module
    (func $print_i32 (import "ono" "print_i32") (param i32))
    (func $i32_symbol (import "ono" "i32_symbol") (result i32))
    (func $read_i32 (import "ono" "read_i32") (result i32))

    (func $main

        (local $x i32)
        (local $x2 i32)
        (local $x3 i32)

        (local $a i32)
        (local $b i32)
        (local $c i32)
        (local $d i32)

        (local $p i32)

        (local.set $x (call $i32_symbol))
        (local.set $x2 (i32.mul (local.get $x) (local.get $x)))
        (local.set $x3 (i32.mul (local.get $x2) (local.get $x)))

        (local.set $a (i32.const 0))
        (local.set $b (i32.const 1))
        (local.set $c (i32.const 2))
        (local.set $d (i32.const 1))

        (local.set $p
            (i32.add
                (i32.add
                    (i32.mul (local.get $a) (local.get $x3))
                    (i32.mul (local.get $b) (local.get $x2))
                )
                (i32.add
                    (i32.mul (local.get $c) (local.get $x))
                    (local.get $d)
                )
            )
        )

        (if (i32.eq (local.get $p) (i32.const 0)) (then unreachable))

    )

    (start $main)
)