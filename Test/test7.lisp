
(define a 11)
(define c 55)
(print (+ 12 11))
;(+ 1 2)


;(+ 1 (+ 3 4))
;(+ 11 22)
(set! c 0.5)
(print ((lambda (a b) (* c a b)) 14 a))

(define (mult_two a1 b1) (* (* a1 b1) 2))
(mult_two 33 44)

