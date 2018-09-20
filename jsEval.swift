//
//  jsEval.swift
//  Script
//
//  Created by Izumu Mishima on 13/07/2016.
//  Copyright © 2016 Izumu Mishima. All rights reserved.
//

//import AppKit
import Foundation
import JavaScriptCore


var textVText: NSMutableAttributedString = NSMutableAttributedString(string: "")
let fontSize: CGFloat = 14

func getVariableName(script: String, context: JSContext) -> String? {
	if script.contains("+=") || script.contains("-=") || script.contains("*=") || script.contains("/=") || script.contains("==") {
		return nil
	}
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
		for char in str {
			charArr.append(char)
		}
		for i in 0..<charArr.count {
			if charArr[i] == "=" {
				if i > 0 {
					str = str[str.startIndex...str.index(str.startIndex, offsetBy: i - 1)]
					//				if context.evaluateScript(str) != JSValue.init(undefinedIn: context) {
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
		for char in str {
			charArr.append(char)
		}
		var k = 0
		for i in 0..<charArr.count {
			if charArr[i] == "(" {
				k = i
				if i > 0 {
					funcName = str[str.startIndex...str.index(str.startIndex, offsetBy: i - 1)]
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

func evaluateJS(script: String, context: JSContext) -> (eval: [JSValue], msg: String) {
	var eval: [JSValue] = []
	var message: String = "undefined"
	var script = script.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
	
	defer {
		appendMessage(message: message)
	}
	
	if script == "" {
		return ([JSValue.init(nullIn: context)], "")
	}
	
	if let (funcName, paraNames) = getFunctionAndParameterNames(script: script, context: context) {
		message = "\(funcName)(\(paraNames))"
		return([context.evaluateScript(script)], message)
		//		return ([context.evaluateScript(script)], message)
	}
	let evaluated = context.evaluateScript(script)
	if script.hasPrefix("for ") {
		message = ""
	} else if let varName = getVariableName(script: script, context: context) {
		let evaluatedValue = context.evaluateScript(varName)!
		var evaluatedValueString = "\(evaluatedValue)"
		if JSValueIsArray(context.jsGlobalContextRef, evaluatedValue.jsValueRef) {
			evaluatedValueString = "[" + evaluatedValueString + "]"
		}
		message = "\(varName) = \(evaluatedValueString)"
	} else if message == "undefined" {
		if evaluated == JSValue.init(undefinedIn: context) {
			if script.hasPrefix("print(") {
				message = ""
				return ([evaluated!], message)
			}
			var ev = false
			var charArr: [Character] = []
			for char in script {
				charArr.append(char)
			}
			for i in 0..<charArr.count {
				if charArr[i] == "(" {
					let s = script[script.startIndex..<script.index(script.startIndex, offsetBy: i)]
					if !String(describing: context.evaluateScript(s)!).contains("return") && context.evaluateScript(s) != JSValue.init(undefinedIn: context){
						message = ""
						ev = true
					}
				}
			}
			if !ev {
				let condensed = script.replacingOccurrences(of: " ", with: "")
				if condensed.contains("){") {
					if condensed.hasPrefix("while") || condensed.hasPrefix("for") || condensed.hasPrefix("if") {
						message = ""
					}
				}
			}
		} else {
			message = "\(evaluated!)"
			if JSValueIsArray(context.jsGlobalContextRef, evaluated!.jsValueRef) {
				message = "[" + message + "]"
			}
		}
	}
	
	if let num = Double(message) {
		if message.contains(".") {
			message = "\(num)"
		}
	}
	return ([evaluated!], message)
}

func jsEval(script: String, context: JSContext) -> (eval: [JSValue], msg: String) {
	var eval: [JSValue] = []
	var message: String = "undefined"
	var script = script.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
	
	if script == "" {
		return ([JSValue.init(nullIn: context)], "")
	}
	
	if ((script.contains(";") && !script.hasPrefix(";")) || (script.contains("\n"))) && !(script.hasPrefix("for ") && !(script.contains("}\n") || script.contains("};"))) {
		while script.hasSuffix(";") || script.hasSuffix("\n") {
			script = script[script.startIndex..<script.index(script.endIndex, offsetBy: -1)]
		}
		var semicolonIndices: [Int] = []
		var charArr: [Character] = []
		for char in script {
			charArr.append(char)
		}
		var bracketLevel = 0
		for i in 0..<charArr.count {
			switch charArr[i] {
			case "(":
				bracketLevel += 1
			case "[":
				bracketLevel += 1
			case "{":
				bracketLevel += 1
			case ")":
				bracketLevel -= 1
			case "]":
				bracketLevel -= 1
			case "}":
				bracketLevel -= 1
			default:
				break
			}
			if (charArr[i] == ";" || charArr[i] == "\n") && bracketLevel == 0 {
				semicolonIndices.append(i + 1)
			}
		}
		message = ""
		
		for j in 0...semicolonIndices.count {
			let start = script.index(script.startIndex, offsetBy: j == 0 ? 0 : semicolonIndices[j - 1])
			let end = script.index(script.startIndex, offsetBy: j < semicolonIndices.count ?  semicolonIndices[j] : script.count)
			var (e, m) = evaluateJS(script: script[start..<end], context: context)
			eval.append(e[0])
			message += "\(m)" //+ (j < semicolonIndices.count && m != "" ? "\n" : "")
		}
		return (eval, message)
	}
	return evaluateJS(script: script, context: context)
}

func printToScreen(message: String) {
	appendMessage(message: message, print: true)
}

func addMaths(jsContext: JSContext) {
	_ = jsContext.evaluateScript("var console = { log: function(message) { _consoleLog(message) } }")
	_ = jsContext.evaluateScript("const print = function(message) { return console.log(message) }")
	let consoleLog: @convention(block) (String) -> Void = { message in
		printToScreen(message: message)
	}
	jsContext.setObject(unsafeBitCast(consoleLog, to: AnyObject.self), forKeyedSubscript: "_consoleLog" as NSCopying & NSObjectProtocol)
	
	_ = jsContext.evaluateScript("const pi = Math.PI")
	_ = jsContext.evaluateScript("const e = Math.E")
	_ = jsContext.evaluateScript("const abs = function(x) { return Math.abs(x) }")
	_ = jsContext.evaluateScript("const ceil = function(x) { return Math.ceil(x) }")
	_ = jsContext.evaluateScript("const exp = function(x) { return Math.exp(x) }")
	_ = jsContext.evaluateScript("const floor = function(x) { return Math.floor(x) }")
	_ = jsContext.evaluateScript("const log = function(x) { return Math.log(x) }")
	_ = jsContext.evaluateScript("const pow = function(x, y) { return Math.pow(x, y) }")
	_ = jsContext.evaluateScript("const random = function(x) { return Math.random(x) }")
	_ = jsContext.evaluateScript("const round = function(x) { return Math.round(x) }")
	_ = jsContext.evaluateScript("const sqrt = function(x) { return Math.sqrt(x) }")
	
	_ = jsContext.evaluateScript("const sin = function(x) { return Math.sin(x) }")
	_ = jsContext.evaluateScript("const cos = function(x) { return Math.cos(x) }")
	_ = jsContext.evaluateScript("const tan = function(x) { return Math.tan(x) }")
	_ = jsContext.evaluateScript("const asin = function(x) { return Math.asin(x) }")
	_ = jsContext.evaluateScript("const acos = function(x) { return Math.acos(x) }")
	_ = jsContext.evaluateScript("const atan = function(x) { return Math.atan(x) }")
	_ = jsContext.evaluateScript("const atan2 = function(x, y) { return Math.atan2(x,y) }")
}
