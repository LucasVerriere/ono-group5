(module

	(func $print_i32 (import "ono" "print_i32") (param i32))
	(func $i32_symbol (import "ono" "i32_symbol") (result i32))
	(func $read_i32 (import "ono" "read_i32") (result i32))
	(func $print_header (import "ono" "print_header"))
	(func $print_solutions (import "ono" "print_solutions"))
	(func $prompt (import "ono" "prompt"))
	(func $assume (import "ono" "assume") (param i32))
	(func $restrict_x (import "ono" "restrict_x") (result i32))
	
	
	(func $eval_poly (param $x i32) (param $a i32) (param $b i32) (param $c i32) (param $d i32) (result i32)
		(local $x2 i32)
		(local $x3 i32)
		(local.set $x2 (i32.mul (local.get $x) (local.get $x)))
		(local.set $x3 (i32.mul (local.get $x2) (local.get $x)))
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

	(func $search_for_one_solution
		(param $x1 i32) (param $x2 i32) (param $x3 i32)
		(param $p1 i32)
		(call $assume (i32.eq (local.get $x1) (local.get $x2)))
		(call $assume (i32.eq (local.get $x1) (local.get $x3)))
		(call $assume (i32.eq (local.get $p1) (i32.const 0)))
		(unreachable)
	)

	(func $search_for_two_solutions
		(param $x1 i32) (param $x2 i32) (param $x3 i32)
		(param $p1 i32) (param $p2 i32)
		(call $assume (i32.ne (local.get $x2) (local.get $x1)))
		(call $assume (i32.eq (local.get $x3) (local.get $x1)))
		(call $assume (i32.eq (local.get $p1) (i32.const 0)))
		(call $assume (i32.eq (local.get $p2) (i32.const 0)))
		(unreachable)
	)

	(func $search_for_three_solutions
		(param $x1 i32) (param $x2 i32) (param $x3 i32)
		(param $p1 i32) (param $p2 i32) (param $p3 i32)
		(call $assume (i32.ne (local.get $x2) (local.get $x1)))
		(call $assume (i32.ne (local.get $x3) (local.get $x1)))
		(call $assume (i32.ne (local.get $x3) (local.get $x2)))
		(call $assume (i32.eq (local.get $p1) (i32.const 0)))
		(call $assume (i32.eq (local.get $p2) (i32.const 0)))
		(call $assume (i32.eq (local.get $p3) (i32.const 0)))
		(unreachable)
	)

	
	(func $main
		
		(local $x1 i32) (local $x2 i32) (local $x3 i32)
		(local $a i32) (local $b i32) (local $c i32) (local $d i32)
		(local $p1 i32) (local $p2 i32) (local $p3 i32)
		(local $solutions_count i32)

		(call $print_header)

		(local.set $x1 (call $i32_symbol))
		(local.set $x2 (call $i32_symbol))
		(local.set $x3 (call $i32_symbol))

		(if (call $restrict_x)
			(then
				(call $assume (i32.ge_s (local.get $x1) (i32.const -100)))
				(call $assume (i32.le_s (local.get $x1) (i32.const 100)))
				(call $assume (i32.ge_s (local.get $x2) (i32.const -100)))
				(call $assume (i32.le_s (local.get $x2) (i32.const 100)))
				(call $assume (i32.ge_s (local.get $x3) (i32.const -100)))
				(call $assume (i32.le_s (local.get $x3) (i32.const 100)))
			)
		)

		(local.set $solutions_count (call $i32_symbol))

		(call $prompt)
		(local.set $a (call $read_i32))
		(call $prompt)
		(local.set $b (call $read_i32))
		(call $prompt)
		(local.set $c (call $read_i32))
		(call $prompt)
		(local.set $d (call $read_i32))

		(local.set $p1 (call $eval_poly (local.get $x1) (local.get $a) (local.get $b) (local.get $c) (local.get $d)))
		(local.set $p2 (call $eval_poly (local.get $x2) (local.get $a) (local.get $b) (local.get $c) (local.get $d)))
		(local.set $p3 (call $eval_poly (local.get $x3) (local.get $a) (local.get $b) (local.get $c) (local.get $d)))


		(call $print_solutions)

		(if (i32.eq (local.get $solutions_count) (i32.const 1))
		(then
			(call $search_for_one_solution (local.get $x1) (local.get $x2) (local.get $x3) (local.get $p1))
		))

		(if (i32.eq (local.get $solutions_count) (i32.const 2))
		(then 
			(call $search_for_two_solutions (local.get $x1) (local.get $x2) (local.get $x3) (local.get $p1) (local.get $p2))
		))

		(if (i32.eq (local.get $solutions_count) (i32.const 3))
		(then
			(call $search_for_three_solutions (local.get $x1) (local.get $x2) (local.get $x3) (local.get $p1) (local.get $p2) (local.get $p3))
		))

	)

	(start $main)

)