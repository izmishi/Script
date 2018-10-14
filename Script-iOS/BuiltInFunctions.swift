//
//  BuiltInFunctions.swift
//  Script-iOS
//
//  Created by Izumu Mishima on 14/10/2018.
//  Copyright © 2018 Izumu Mishima. All rights reserved.
//

import Foundation

let builtInLisp = """
(define dotInternal (lambda (x y sum)
	(begin
		(define answer sum)
		(if (equal? x ())
			()
			(if (equal? y ())
				()
				(begin (define c (* (car x) (car y))) (set! answer (dotInternal (cdr x) (cdr y) (+ sum c))))
			)
		)
		answer
	)
))
(define dot (lambda (x y)
	(begin (dotInternal x y 0))
))
"""
