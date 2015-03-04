
(define (fact n)
	(let ((r 1))
		(let ((k (call/cc (lambda (c) c))))
			(set! r (* r n))
			(set! n (- n 1))
			(print "run loop" n)
			(if (eq? n 1) 
				(begin
					(print "return r" r)
					r)
				(begin
					(print "loop back")
					(k k))
				))))

;(fact 6)






(define (f return)
  (return 2)
  3)
 
;(print (f (lambda (x) x))) ; displays 3
;(print (call/cc f)) ; displays 2







(define (for-each f lst)
	(if (pair? lst)
		(cons (f (car lst)) (for-each f (cdr lst)))
		'()))



;; [LISTOF X] -> ( -> X u 'you-fell-off-the-end)
(define (generate-one-element-at-a-time lst)
 
  ;; Hand the next item from a-list to "return" or an end-of-list marker
  (define (control-state return)
    (for-each 
     (lambda (element)
               (set! return (call/cc
                              (lambda (resume-here)
                                ;; Grab the current continuation
                               (set! control-state resume-here)
                               (return element)))))
     lst)
    (return 'you-fell-off-the-end))
 
  ;; (-> X u 'you-fell-off-the-end)
  ;; This is the actual generator, producing one item from a-list at a time
  (define (generator)
    (call/cc control-state)) 
 
  ;; Return the generator 
  generator)
 
(define generate-digit
  (generate-one-element-at-a-time '(0 1 2)))
 
(display (generate-digit)) ;; 0
(display (generate-digit)) ;; 1
(display (generate-digit)) ;; 2
(display (generate-digit)) ;; you-fell-off-the-end



