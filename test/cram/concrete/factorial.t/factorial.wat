(module

    (func $print_i32 (import "ono" "print_i32") (param i32))

    (func $factorial (param $n i32) (result i32)
        (if (i32.lt_s (local.get $n) (i32.const 1))
            (then (return (i32.const 1)))
        )
        (return (i32.mul (local.get $n) (call $factorial (i32.sub (local.get $n) (i32.const 1)))))
    )


    (func $main
        i32.const 0 call $factorial call $print_i32
        i32.const 1 call $factorial call $print_i32
        i32.const 2 call $factorial call $print_i32
        i32.const 3 call $factorial call $print_i32
        i32.const 4 call $factorial call $print_i32
        i32.const 5 call $factorial call $print_i32
    )

    (start $main)

)