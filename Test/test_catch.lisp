

(catch 'error
	(print '1)
	(print '2)
	(throw 'error 'error_occur)
	(print '3))