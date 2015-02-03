


(print (atom? '(a)))
(atom? (atom? '(a)))
(print "1 + 2 = " (+ 1 2))


(define to_rev (list 'a 'b 'c 'd 'e))

(print 'Reverse:)
(print to_rev)

(define (reverse l)
		(define (reverse l r)
				(if (pair? l)
					(begin
						(reverse (cdr l) (cons (car l) r)))
					(begin
						r)))
		(reverse l '()))

(print 'Result:)
(print (reverse to_rev))
(print (reverse to_rev))

(print '(() () ()))

(print (cons 'list (list to_rev)))
(print (cons 'list '()))
