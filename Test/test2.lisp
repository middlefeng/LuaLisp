


(print (atom? '(a)))
(atom? (atom? '(a)))
(print "1 + 2 = " (+ 1 2))


(define to_rev (list 'a 'b 'c 'd 'e))
(define list2 '(1))

(print 'Reverse:)
(print (tostring to_rev))

(define (reverse l)
		(define (reverse l r)
				(if (pair? l)
					(begin
						(reverse (cdr l) (cons (car l) r)))
					(begin
						r)))
		(reverse l '()))

(print 'Result:)
(print (tostring (reverse to_rev)))
;(tostring (reverse to_rev))
(tostring (reverse to_rev))