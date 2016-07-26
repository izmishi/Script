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
		} else if script.hasPrefix("const ") {
			let index = script.index(script.startIndex, offsetBy: 6)
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
func getFunctionAndParameterNames(script: String, context: JSContext) -> (funcName: String, parameterNames: String)? {
	if script.contains("{") && script.hasPrefix("function"){
		var str = script
		let index = script.index(script.startIndex, offsetBy: 8)
		str = script[index..<script.endIndex].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
		var funcName = ""
		var parameterNames = ""
		var charArr: [Character] = []
		for char in str.characters {
			charArr.append(char)
		}
		var k = 0
		for i in 0..<charArr.count {
			if charArr[i] == "(" {
				k = i
				funcName = str[str.startIndex...str.index(str.startIndex, offsetBy: i - 1)]
				if context.evaluateScript(funcName) != JSValue.init(undefinedIn: context) {
					funcName = funcName.replacingOccurrences(of: " ", with: "")
				}
			} else if charArr[i] == ")" {
				parameterNames = str[str.index(str.startIndex, offsetBy: k + 1)..<str.index(str.startIndex, offsetBy: i)]
				if funcName != "" {
					return (funcName, parameterNames)
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
	var script = script.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
	if script == "" {
		return ([JSValue.init(nullIn: context)], "")
	}
	
	if let (funcName, paraNames) = getFunctionAndParameterNames(script: script, context: context) {
		message = "\(funcName)(\(paraNames))"
		return([context.evaluateScript(script)], message)
		//		return ([context.evaluateScript(script)], message)
	} else if script.contains(";") && !script.hasPrefix(";") && !script.hasPrefix("for ") {
		while script.hasSuffix(";") {
			script = script[script.startIndex..<script.index(script.endIndex, offsetBy: -1)]
		}
		var semicolonIndices: [Int] = []
		var charArr: [Character] = []
		for char in script.characters {
			charArr.append(char)
		}
		
		var bracketLevel = 0
		for i in 0..<charArr.count {
			switch charArr[i] {
			case "(":
				bracketLevel += 1
			case "[":
				bracketLevel += 1
			case ")":
				bracketLevel -= 1
			case "]":
				bracketLevel -= 1
			default:
				continue
			}
			if charArr[i] == ";" && bracketLevel == 0 {
				semicolonIndices.append(i + 1)
			}
		}
		message = ""
		
		for j in 0...semicolonIndices.count {
			let start = script.index(script.startIndex, offsetBy: j == 0 ? 0 : semicolonIndices[j - 1])
			let end = script.index(script.startIndex, offsetBy: j < semicolonIndices.count ?  semicolonIndices[j] : script.characters.count)
			var (e, m) = jsEval(script: script[start..<end].replacingOccurrences(of: ";", with: ""), context: context)
			eval.append(e[0])
			message += "\(m)" + (j < semicolonIndices.count && m != "" ? "\n" : "")
		}
		return (eval, message)
	}
	let evaluated = context.evaluateScript(script)
	if let varName = getVariableName(script: script, context: context) {
		message = "\(varName) = \(context.evaluateScript(varName)!)"
	} else if message == "undefined" {
		if evaluated == JSValue.init(undefinedIn: context) {
			if script.hasPrefix("print(") {
				return ([evaluated!], "")
			}
			var ev = false
			var charArr: [Character] = []
			for char in script.characters {
				charArr.append(char)
			}
			for i in 0..<charArr.count {
				if charArr[i] == "(" {
					let s = script[script.startIndex..<script.index(script.startIndex, offsetBy: i)]
					if !String(context.evaluateScript(s)!).contains("return") && context.evaluateScript(s) != JSValue.init(undefinedIn: context){
						message = ""
						ev = true
					}
				}
			}
			if !ev {
				let condensed = script.replacingOccurrences(of: " ", with: "")
				if condensed.contains("){") {
					if condensed.hasPrefix("while") || condensed.hasPrefix("for") {
						message = ""
					}
				}
			}
		} else {
			message = "\(evaluated!)"
		}
	}
	
	if let num = Double(message) {
		if message.contains(".") {
			message = "\(num)"
		}
	}
	return ([evaluated!], message)
}
func addMaths(jsContext: JSContext) {
	_ = jsContext.evaluateScript("const pi = Math.PI")
	_ = jsContext.evaluateScript("const e = Math.E")
	_ = jsContext.evaluateScript("const abs = function(x) {\n\treturn Math.abs(x)\n}")
	_ = jsContext.evaluateScript("const ceil = function(x) {\n\treturn Math.ceil(x)\n}")
	_ = jsContext.evaluateScript("const exp = function(x) {\n\treturn Math.exp(x)\n}")
	_ = jsContext.evaluateScript("const floor = function(x) {\n\treturn Math.floor(x)\n}")
	_ = jsContext.evaluateScript("const log = function(x) {\n\treturn Math.log(x)\n}")
	_ = jsContext.evaluateScript("const pow = function(x, y) {\n\treturn Math.pow(x, y)\n}")
	_ = jsContext.evaluateScript("const random = function(x) {\n\treturn Math.random(x)\n}")
	_ = jsContext.evaluateScript("const round = function(x) {\n\treturn Math.round(x)\n}")
	_ = jsContext.evaluateScript("const sqrt = function(x) {\nr\teturn Math.sqrt(x)\n}")
	
	_ = jsContext.evaluateScript("const sin = function(deg) {\n\treturn Math.sin(deg * pi / 180)\n}")
	_ = jsContext.evaluateScript("const cos = function(deg) {\n\treturn Math.cos(deg * pi / 180)\n}")
	_ = jsContext.evaluateScript("const tan = function(deg) {\n\treturn Math.tan(deg * pi/ 180)\n}")
	_ = jsContext.evaluateScript("const asin = functionx) {\n\treturn Math.asin(x) * 180 / pi\n}")
	_ = jsContext.evaluateScript("const acos = function(x) {\n\treturn Math.acos(x) * 180 / pi\n}")
	_ = jsContext.evaluateScript("const atan = function(x) {\n\treturn Math.atan(x) * 180 / pi\n}")
	_ = jsContext.evaluateScript("const atan2 = function(x, y) {\n\treturn Math.atan2(x,y) * 180 / pi\n}")
}
