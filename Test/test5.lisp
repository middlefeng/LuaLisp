

(define let_result
	(let ((a 11) (b 22))
	 	 (+ a b)))

(print "Result 1" let_result)

(set! let_result
(let ((a 22))
	 ((lambda (x) (+ a x)) 1)))

(print "Result 2" let_result)


((if true * +) 2 3)
