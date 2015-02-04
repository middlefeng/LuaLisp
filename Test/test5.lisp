

(define let_result
	(let ((a 11) (b 22))
	 	 (+ a b)))

(print let_result)

(let ((a 22))
	 ((lambda (x) (+ a x)) 1))
