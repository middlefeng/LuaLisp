

(catch 'error
	(print '1)
	(print '2)
	(throw 'error 'error_occur)
	(print '3))


(catch 2
	(* 7 (catch 1
		(* 3 (catch 2
			(throw 1 (throw 2 5)))))))


