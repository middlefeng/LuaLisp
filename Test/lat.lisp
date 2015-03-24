

(define (lat? l)
	(cond ((null? l) true)
		  ((atom? (car l)) (lat? (cdr l)))
		  (else false) ) )


(define (member? a lat)
	(cond ((null? lat) false)
		  ((lat? lat) (or (eq? (car lat) a) (member? a (cdr lat))))
		  (else false) ) )

; (member? 1 '(1 2 3))

; (define lat '(1 2 3))
; (print lat?)

; (lat? lat)
; (print lat)
