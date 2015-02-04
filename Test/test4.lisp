

(define v1 '(a))

(define (append_v1 e)
		(set! v1 (cond ((null? e) v1)
			   		   ((atom? e) (cons e v1))
			  		   (else (cons (car e) (append_v1 (cdr e))))))
		v1)

;(append_v1 '(b c))

(define (append_list exp)
		(lambda (exp_outter)
		 		(append_v1 exp_outter)
		 		(append_v1 exp)))

;((lambda () (append_v1  '(1 2))))
(print (tostring car))
((append_list '(11 22)) "abc")
