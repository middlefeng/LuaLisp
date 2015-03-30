

; function factorCount(n)
; 	local square = math.sqrt(n)
; 	local isquare = math.floor(square)
; 	local count = (isquare == square) and -1 or 0

; 	for candidate = 1, isquare do
; 		if (0 == math.fmod(n, candidate)) then
; 			count = count + 2
; 		end
; 	end

; 	return count
; end


; local triangle = 1
; local index = 1

; while factorCount(triangle) < 700 do
; 	index = index + 1
; 	triangle = triangle + index
; end

; local time = benchmark.end_run()



(define (factor_count n)
	(define square (sqrt n))
	(define isquare (floor square))

	(define (do_count candidate count)
			(if (eq? candidate isquare)
				(if (eq? 0 (mod n candidate))
					(+ count 2)
					count)
				(if (eq? 0 (mod n candidate))
					(do_count (+ 1 candidate) (+ 2 count))
					(do_count (+ 1 candidate) count) ) ) )

	(if (eq? square isquare)
			(do_count 1 -1)
			(do_count 1 0) ) )


(define (do_main index triangle)
		(if (< (factor_count triangle) iterate_num)
			(do_main (+ 1 index) (+ 1 index triangle))
			triangle) )

(do_main 1 1)


