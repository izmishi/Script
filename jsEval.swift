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
	if script.contains("=") && !script.hasPrefix("="){
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
				break
			}
		}
	}
	return nil
}

func jsEval(script: String, context: JSContext) -> (eval: [JSValue], msg: String) {
	var eval: [JSValue] = []
	var message: String = "undefined"
	var script = script.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines())
	if script == "" {
		return ([JSValue.init(nullIn: context)], "")
	}
	if script.contains(";") && !script.hasPrefix(";") {
		while script.hasSuffix(";") {
			print(script)
			script = script[script.startIndex..<script.index(script.endIndex, offsetBy: -1)]
		}
		var semicolonIndices: [Int] = []
		var charArr: [Character] = []
		for char in script.characters {
			charArr.append(char)
		}
		for i in 0..<charArr.count {
			if charArr[i] == ";" {
				semicolonIndices.append(i + 1)
			}
		}
		message = ""
		for j in 0...semicolonIndices.count {
			let start = script.index(script.startIndex, offsetBy: j == 0 ? 0 : semicolonIndices[j - 1])
			let end = script.index(script.startIndex, offsetBy: j < semicolonIndices.count ?  semicolonIndices[j] : script.characters.count)
			var (e, m) = jsEval(script: script[start..<end].replacingOccurrences(of: ";", with: ""), context: context)
			eval.append(e[0])
			message += "\(m)" + (j < semicolonIndices.count ? "\n" : "")
		}
		return (eval, message)
	}
	let evaluated = context.evaluateScript(script)
	if let varName = getVariableName(script: script, context: context) {
		message = "\(varName) = \(context.evaluateScript(varName)!)"
	} else if evaluated == JSValue.init(undefinedIn: context) {
		if context.evaluateScript("Math.\(script)") != JSValue.init(undefinedIn: context) {
			return jsEval(script: "Math.\(script)", context: context)
		}
	} else {
		message = "\(evaluated!)"
	}
	return ([evaluated!], message)
}
