//
//  jsEval.swift
//  Script
//
//  Created by Izumu Mishima on 13/07/2016.
//  Copyright © 2016 Izumu Mishima. All rights reserved.
//

import Foundation
import JavaScriptCore

func getVariableName(script: String, context: JSContext) -> String? {
	if script.contains("=") {
		var str = script
		if script.hasPrefix("var ") {
			let index = script.index(script.startIndex, offsetBy: 4)
			str = script[index..<script.endIndex]
		}
		var charArr: [Character] = []
		for char in str.characters {
			charArr.append(char)
		}
		for i in 0..<charArr.count {
			if charArr[i] == "=" {
				str = str[str.startIndex...str.index(str.startIndex, offsetBy: i - 1)]
				if context.evaluateScript(str) != JSValue.init(undefinedIn: context) {
					return str.replacingOccurrences(of: " ", with: "")
				}
			}
		}
	}
	return nil
}

func jsEval(script: String, context: JSContext) -> (eval: JSValue, msg: String) {
	let evaluated = context.evaluateScript(script)
	var message: String = "undefined"
	if let varName = getVariableName(script: script, context: context) {
		message = "\(varName) = \(context.evaluateScript(varName)!)"
	} else if evaluated == JSValue.init(undefinedIn: context) {
		if context.evaluateScript("Math.\(script)") != JSValue.init(undefinedIn: context) {
			return jsEval(script: "Math.\(script)", context: context)
		}
	} else {
		message = "\(evaluated!)"
	}
	return (evaluated!, message)
}
