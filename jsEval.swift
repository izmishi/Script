//
//  jsEval.swift
//  Script
//
//  Created by Izumu Mishima on 13/07/2016.
//  Copyright © 2016 Izumu Mishima. All rights reserved.
//

import Foundation
import JavaScriptCore

func jsEval(script: String, context: JSContext) -> (eval: JSValue, msg: String) {
	let evaluated = context.evaluateScript(script)
	var message: String = ""
	if evaluated == JSValue.init(undefinedIn: context) {
		if script.hasPrefix("var ") {
			let index = script.index(script.startIndex, offsetBy: 4)
			message = script[index..<script.endIndex]
		} else {
			if context.evaluateScript("Math.\(script)") != JSValue.init(undefinedIn: context) {
				return jsEval(script: "Math.\(script)", context: context)
			} else {
				message = "undefined"
			}
		}
	} else {
		message = "\(evaluated!)"
	}
	return (evaluated!, message)
}
