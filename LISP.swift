//
//  LISP.swift
//  
//
//  Created by Izumu Mishima on 20/09/2018.
//

import Foundation

/*
Fundamental forms:
/define
/lambda
/quote
/'
/if
define-syntax
let-syntax
letrec-syntax
syntax-rules
/set!

Derived forms:
do
let
let*
letrec
cond
case
and
or
/begin
named let
delay
unquote
unquote-splicing
quasiquote
*/

enum LispError: Error {
	case parseError
	case incorrectArgumentCount(shouldBe: Int)
	case tooFewArguments(shouldBeAtLeast: Int)
	case noCar
	case evaluationError(message: String)
	case typeError(message: String)
	case undefinedError(message: String)
}
enum LispMessage: Error {
	case typeDescription(_: String)
}

enum LispType {
	case symbol
	case number
	case bool
	case list
	case nilType
}

typealias Symbol = String
typealias Number = Double
typealias List = [Any]

struct Atom: CustomStringConvertible, Equatable {
	
	private var values: (symbol: Symbol?, number: Number?, bool: Bool?)!
	
	var type: LispType {
		if values.number != nil {
			return .number
		} else if values.symbol != nil {
			return .symbol
		} else if values.bool != nil {
			return .bool
		} else {
			return .nilType
		}
	}
	
	static func == (lhs: Atom, rhs: Atom) -> Bool {
		return lhs.values == rhs.values
	}
	
	
	var description: String {
		if values.number != nil {
			return values.number!.description
		} else if values.symbol != nil {
			return String(values.symbol!)
		} else if values.bool != nil {
			return String(values.bool! ? "#t" : "#f")
		} else {
			return "nil"
		}
	}
	
	var value: Any? {
		return (values.number != nil ? values.number! : (values.symbol != nil ? values.symbol! : values.bool!) as Any?)
	}
	
	init(_ bool: Bool) {
		values = (nil, nil, bool)
	}
	
	init(_ number: Number) {
		values = (nil, number, nil)
	}
	
	init(_ symbol: Symbol) {
		if let number = Number(symbol) {
			values = (nil, number, nil)
		} else {
			if symbol == "#f" {
				values = (nil, nil, false)
			} else if symbol == "#t" {
				values = (nil, nil, true)
			} else {
				values = (symbol, nil, nil)
			}
		}
	}
	
	init() {
		values = (nil, nil, nil)
	}
	
	init(_ thing: Any) {
		if let number = thing as? Number {
			self.init(number)
		} else if let symbol = thing as? Symbol {
			self.init(symbol)
		} else if let bool = thing as? Bool {
			self.init(bool)
		} else {
			self.init()
		}
	}
	
}

struct Expression: CustomStringConvertible, Equatable {
	private var values: (atom: Atom?, list: List?, closure: LispClosure?)!
	
	static func == (lhs: Expression, rhs: Expression) -> Bool {
		guard lhs.values?.atom != nil && rhs.values?.atom != nil else {
			return false
		}
		return lhs.values?.atom == rhs.values?.atom
	}
	
	
	var value: Any? {
		return values.list != nil ? values.list! : (values.atom != nil ? values.atom!.value : values.closure!) as Any?
	}
	
	init(_ atom: Atom) {
		values = (atom, nil, nil)
	}
	
	init(_ list: List) {
		values = (nil, list, nil)
	}
	
	init(_ thing: Any) {
		if let exp = thing as? Expression {
			values = exp.values
		} else if let atom = thing as? Atom {
			values = (atom, nil, nil)
		} else if let list = thing as? List {
			values = (nil, list, nil)
		} else if let closure = thing as? LispClosure {
			values = (nil, nil, closure)
		} else {
			values = (Atom(thing), nil, nil)
		}
	}
	
	init() {
		values = (nil, nil, nil)
	}
	
	var description: String {
		if values.atom != nil {
			return values.atom!.description
		} else if values.list != nil {
			if values.list!.count == 0 {
				return "()"
			}
			return values.list!.description
		} else if values.closure != nil {
			return "#<Closure>"
		} else {
			return "nil"
		}
	}
}

typealias LispClosure = (List) throws -> Expression

class Environment {
	var symbols: [Symbol: LispClosure] = [:]
	
	var lambdas: [LispClosure] = []
	
	var outer: Environment?
	
	init() {
		setUp()
	}
	
	
	init(syms: [Symbol] = [], arguments: List = [], outer outerEnv: Environment? = nil) throws {
		setUp()
		outer = outerEnv
		guard arguments.count >= syms.count else {
			throw LispError.incorrectArgumentCount(shouldBe: syms.count)
		}
		for i in 0..<syms.count {
			symbols[syms[i]] = { (_ array: List) -> Expression in
				try evaluate(Expression(arguments[i]), environment: self)
			}
		}
	}
	
	func find(symbol: Symbol) throws -> Environment? {
		if symbols[symbol] != nil {
			return self
		} else if let outerEnv = outer {
			return try outerEnv.find(symbol: symbol)
		} else {
			throw LispError.undefinedError(message: "\(symbol) is undefined")
		}
	}
	
	private func setUp() {
		//Syntax
		for symbol in ["define", "set!", "if", "quote", "lambda", "begin"] {
			symbols[symbol] = {(_ list: List) -> Expression in
				throw LispMessage.typeDescription("Syntax \(symbol)")
			}
		}
		
		//Functions
		symbols["list"] = {(_ list: List) -> Expression in
			guard list.count > 0 else {
				throw LispMessage.typeDescription("Function (list x...)")
			}
			var l = list
			l.removeFirst()
			return Expression(l)
		}
		
		symbols["car"] = { (list: List) -> Expression in
			guard list.count > 0 else {
				throw LispMessage.typeDescription("Function (car (list))")
			}
			guard list.count == 2 else {
				throw LispError.incorrectArgumentCount(shouldBe: 1)
			}
			if let l = list[1] as? List {
				if let car = l.first {
					return Expression(car)
				} else {
					throw LispError.noCar
				}
			} else {
				throw LispError.typeError(message: "Attempt to apply car to non-list item, \(list[1])")
			}
		}
		symbols["cdr"] = { (list: List) -> Expression in
			guard list.count > 0 else {
				throw LispMessage.typeDescription("Function (cdr (list))")
			}
			guard list.count == 2 else {
				throw LispError.incorrectArgumentCount(shouldBe: 1)
			}
			if let l = list[1] as? List {
				let cdr = Array(l[1..<l.count])
				return Expression(cdr)
			} else {
				throw LispError.typeError(message: "Attempt to apply cdr to non-list item, \(list[1])")
			}
		}
		
		symbols["#f"] = { (_: List) -> Expression in
			return Expression("#f")
		}
		symbols["#t"] = { (_: List) -> Expression in
			return Expression("#t")
		}
		
		symbols["pi"] = { (_: List) -> Expression in
			return Expression(Number.pi)
		}
		symbols["e"] = { (_: List) -> Expression in
			return Expression(M_E)
		}
		
		symbols["+"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (+ x...)")
			}
			var arr = try self.getNumbers(from: array)
			if arr.count == 0 {
				return Expression(0.0)
			}
			let s = arr.removeFirst()
			return Expression(arr.reduce(s, +))
		}
		symbols["-"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (- x...)")
			}
			var arr = try self.getNumbers(from: array)
			guard arr.count > 0 else {
				throw LispError.tooFewArguments(shouldBeAtLeast: 1)
			}
			if arr.count == 1 {
				return Expression(-arr[0])
			}
			let s = arr.removeFirst()
			return Expression(arr.reduce(s, -))
		}
		symbols["*"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (* x...)")
			}
			var arr = try self.getNumbers(from: array)
			if arr.count == 0 {
				return Expression(1.0)
			}
			let s = arr.removeFirst()
			return Expression(arr.reduce(s, *))
		}
		symbols["/"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (/ x...)")
			}
			var arr = try self.getNumbers(from: array)
			guard arr.count > 0 else {
				throw LispError.tooFewArguments(shouldBeAtLeast: 1)
			}
			if arr.count == 1 {
				return Expression(1.0 / arr[0])
			}
			let s = arr.removeFirst()
			return Expression(arr.reduce(s, /))
		}
		symbols["sin"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (sin x)")
			}
			let x = try self.getNumbers(from: array)
			guard x.count == 1 else {
				throw LispError.incorrectArgumentCount(shouldBe: 1)
			}
			return Expression(sin(x[0]))
		}
		symbols["cos"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (cos x)")
			}
			let x = try self.getNumbers(from: array)
			guard x.count == 1 else {
				throw LispError.incorrectArgumentCount(shouldBe: 1)
			}
			return Expression(cos(x[0]))
		}
		symbols["tan"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (tan x)")
			}
			let x = try self.getNumbers(from: array)
			guard x.count == 1 else {
				throw LispError.incorrectArgumentCount(shouldBe: 1)
			}
			return Expression(tan(x[0]))
		}
		symbols["asin"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (asin x)")
			}
			let x = try self.getNumbers(from: array)
			guard x.count == 1 else {
				throw LispError.incorrectArgumentCount(shouldBe: 1)
			}
			return Expression(asin(x[0]))
		}
		symbols["acos"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (acos x)")
			}
			let x = try self.getNumbers(from: array)
			guard x.count == 1 else {
				throw LispError.incorrectArgumentCount(shouldBe: 1)
			}
			return Expression(acos(x[0]))
		}
		symbols["atan"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (atan x)")
			}
			let x = try self.getNumbers(from: array)
			guard x.count == 1 else {
				throw LispError.incorrectArgumentCount(shouldBe: 1)
			}
			return Expression(atan(x[0]))
		}
		symbols["exp"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (exp x)")
			}
			let x = try self.getNumbers(from: array)
			guard x.count == 1 else {
				throw LispError.incorrectArgumentCount(shouldBe: 1)
			}
			return Expression(exp(x[0]))
		}
		symbols["log"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (log x)")
			}
			let x = try self.getNumbers(from: array)
			guard x.count == 1 else {
				throw LispError.incorrectArgumentCount(shouldBe: 1)
			}
			return Expression(log(x[0]))
		}
		symbols["expt"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (expt x y)")
			}
			let x = try self.getNumbers(from: array)
			guard x.count == 2 else {
				throw LispError.incorrectArgumentCount(shouldBe: 2)
			}
			return Expression(pow(x[0], x[1]))
		}
		symbols["sqrt"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (sqrt x)")
			}
			let x = try self.getNumbers(from: array)
			guard x.count == 1 else {
				throw LispError.incorrectArgumentCount(shouldBe: 1)
			}
			return Expression(sqrt(x[0]))
		}
		symbols["abs"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (abs x)")
			}
			let x = try self.getNumbers(from: array)
			guard x.count == 1 else {
				throw LispError.incorrectArgumentCount(shouldBe: 1)
			}
			return Expression(abs(x[0]))
		}
		symbols["round"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (round x)")
			}
			let x = try self.getNumbers(from: array)
			guard x.count == 1 else {
				throw LispError.incorrectArgumentCount(shouldBe: 1)
			}
			return Expression(round(x[0]))
		}
		symbols["mod"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (mod x y)")
			}
			let x = try self.getNumbers(from: array)
			guard x.count == 2 else {
				throw LispError.incorrectArgumentCount(shouldBe: 2)
			}
			return Expression(x[0].truncatingRemainder(dividingBy: x[1]))
		}
		symbols["max"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (max x...)")
			}
			let arr = try self.getNumbers(from: array)
			if arr.count == 0 {
				throw LispError.tooFewArguments(shouldBeAtLeast: 1)
			}
			if let max = arr.max() {
				return Expression(max)
			} else {
				throw LispError.evaluationError(message: "Couldn't find the maximum of \(arr)")
			}
		}
		symbols["min"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (min x...)")
			}
			let arr = try self.getNumbers(from: array)
			if arr.count == 0 {
				throw LispError.tooFewArguments(shouldBeAtLeast: 1)
			}
			if let min = arr.min() {
				return Expression(min)
			} else {
				throw LispError.evaluationError(message: "Couldn't find the minimum of \(arr)")
			}
		}
		
		symbols["<"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (< x y)")
			}
			let args = try self.getNumbers(from: array)
			guard args.count == 2 else {
				throw LispError.incorrectArgumentCount(shouldBe: 2)
			}
			return Expression(args[0] < args[1])
		}
		symbols["<="] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (<= x y)")
			}
			let args = try self.getNumbers(from: array)
			guard args.count == 2 else {
				throw LispError.incorrectArgumentCount(shouldBe: 2)
			}
			return Expression(args[0] <= args[1])
		}
		symbols[">"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (> x y)")
			}
			let args = try self.getNumbers(from: array)
			guard args.count == 2 else {
				throw LispError.incorrectArgumentCount(shouldBe: 2)
			}
			return Expression(args[0] > args[1])
		}
		symbols[">="] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (>= x y)")
			}
			let args = try self.getNumbers(from: array)
			guard args.count == 2 else {
				throw LispError.incorrectArgumentCount(shouldBe: 2)
			}
			return Expression(args[0] >= args[1])
		}
		symbols["="] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (= x y)")
			}
			let args = try self.getNumbers(from: array)
			guard args.count == 2 else {
				throw LispError.incorrectArgumentCount(shouldBe: 2)
			}
			return Expression(args[0] == args[1])
		}
		symbols["not"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (not x)")
			}
			let args = try self.getBools(from: array)
			guard args.count == 1 else {
				throw LispError.incorrectArgumentCount(shouldBe: 1)
			}
			return Expression(!args[0])
		}
		
		
		//Refer to the same thing in memory
		/*symbols["eq?"] = {(_ array: List) -> Expression in
		guard array.count > 0 else {
		throw LispMessage.typeDescription("Function (eq? a b)")
		}
		var args = array
		guard args.count == 2 else {
		throw LispError.incorrectArgumentCount(shouldBe: 2)
		}
		let eq: Bool = try self.getExpressionFor(symbol: "\(args[0])") == self.getExpressionFor(symbol: "\(args[1])")
		return Expression(eq)
		}*/
		
		//Same value
		symbols["eqv?"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (eqv? a b)")
			}
			let args = array
			guard args.count == 3 else {
				throw LispError.incorrectArgumentCount(shouldBe: 2)
			}
			let eq: Bool = try evaluate(Expression(args[1]), environment: self) == evaluate(Expression(args[2]), environment: self)
			return Expression(eq)
		}
		
		//Compares if two lists are the same
		symbols["equal?"] = {(_ array: List) -> Expression in
			guard array.count > 0 else {
				throw LispMessage.typeDescription("Function (equal? (list) (list))")
			}
			let args = try self.getLists(from: array)
			guard args.count == 2 else {
				throw LispError.incorrectArgumentCount(shouldBe: 2)
			}
			if args[0].count != args[1].count {
				return Expression(false)
			}
			let a = args[0]
			let b = args[1]
			for i in 0..<a.count {
				if try evaluate(Expression(a[i]), environment: self) != evaluate(Expression(b[i]), environment: self) {
					return Expression(false)
				}
			}
			return Expression(true)
		}
		
	}
	
	private func getNumbers(from array: List) throws -> [Number] {
		var numberArray: [Number] = []
		for thing in array[1..<array.count] {
			if let number = thing as? Number {
				numberArray.append(number)
			} else if let symbol = thing as? Symbol {
				if let num = try symbols[symbol]?([]).value as? Number {
					numberArray.append(num)
				} else {
					throw LispError.typeError(message: "Expected a number, but got \(Expression(thing))")
				}
			} else {
				throw LispError.typeError(message: "Expected a number, but got \(Expression(thing))")
			}
		}
		return numberArray
	}
	
	private func getBools(from list: List) throws -> [Bool] {
		var boolArray: [Bool] = []
		for thing in list[1..<list.count] {
			if let bool = thing as? Bool {
				boolArray.append(bool)
			} else if let symbol = thing as? Symbol {
				if let bool = try symbols[symbol]?([]).value as? Bool {
					boolArray.append(bool)
				} else {
					throw LispError.typeError(message: "Expected a boolean value, but got \(Expression(thing))")
				}
			} else {
				throw LispError.typeError(message: "Expected a boolean value, but got \(Expression(thing))")
			}
			
		}
		return boolArray
	}
	
	private func getLists(from list: List) throws -> [List] {
		var listArray: [List] = []
		for thing in list[1..<list.count] {
			if let list = thing as? List {
				listArray.append(list)
			} else if let symbol = thing as? Symbol {
				if let list = try symbols[symbol]?([]).value as? List {
					listArray.append(list)
				} else {
					throw LispError.typeError(message: "Expected a list, but got \(Expression(thing))")
				}
			} else {
				throw LispError.typeError(message: "Expected a list, but got \(Expression(thing))")
			}
			
		}
		return listArray
	}
	
	func getExpressionFor(symbol: Symbol) throws -> Expression {
		if let object = symbols[symbol] {
			do {
				if let atom = try object([]).value {
					return Expression(atom)
				} else {
					return Expression(object)
				}
			} catch LispMessage.typeDescription(let description) {
				throw LispMessage.typeDescription(description)
			} catch {
				throw LispMessage.typeDescription("Closure")
			}
		} else {
			throw LispError.undefinedError(message: "\(symbol) doesn't exist")
		}
	}
}

class Procedure {
	var body: Expression!
	var parameters: [Symbol]!
	var environment: Environment!
	
	init(params: [Symbol], bdy: Expression, env: Environment) {
		parameters = params
		body = bdy
		environment = env
	}
	
	func call(with params: List, env: Environment) throws -> Expression {
		return try evaluate(body, environment: Environment(syms: parameters, arguments: params, outer: env))
	}
}


func tokenise(_ string: String) -> [String] {
	return string.replacingOccurrences(of: "(", with: " ( ").replacingOccurrences(of: ")", with: " ) ").replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "\t", with: " ").replacingOccurrences(of: "\'", with: " \' ").split(separator: " ").map {String($0)}
}

func readFromTokens(_ tokensList: [String]) -> (expression: Expression, count: Int) {
	var tokens = tokensList
	if tokens.count == 0 {
		print("Error: token count == 0")
		return (Expression(), 0)
	}
	
	var list: List = []
	var count: Int = 0
	var shouldQuote: Bool = false
	
	func addToList(thing: Any, quote: Bool) {
		if quote {
			list.append([Atom("quote").value! as Any, thing])
		} else {
			list.append(thing)
		}
	}
	
	for i in 0..<tokens.count {
		if i + 1 > tokens.count {
			break
		}
		let token = tokens[i]
		count += 1
		
		if token == "(" {
			let toAppend = readFromTokens(Array(tokens[(i + 1)..<tokens.count]))
			addToList(thing: toAppend.expression, quote: shouldQuote)
			tokens.removeSubrange((i)..<(i + toAppend.count))
			count += toAppend.count
		} else if token == ")" {
			return (Expression(list), count)
		} else if token == "\'" {
			shouldQuote = true
			continue
		} else {
			addToList(thing: Atom(token).value! as Any, quote: shouldQuote)
		}
		shouldQuote = false
	}
	
	return (Expression(list), count)
}

func parse(_ program: String) throws -> Expression {
	guard program.filter({ $0 == "("}).count == program.filter({ $0 == ")"}).count else {
		throw LispError.parseError
	}
	return readFromTokens(tokenise(program)).expression
}

func evaluate(_ exp: Expression, environment env: Environment, quote: Bool = false) throws -> Expression {
	if quote {
		if let list = exp.value as? List {
			return Expression(try list.map{ try evaluate(Expression($0), environment: env, quote: true) })
		} else {
			return Expression(exp)
		}
	}
	
	if let list = exp.value as? List {
		if list.count == 0 {
			return Expression([])
		}
		if let firstSymbol = list.first as? Symbol {
			if firstSymbol == "if" {
				guard list.count == 4 else {
					throw LispError.incorrectArgumentCount(shouldBe: 3)
				}
				if let condition = try? evaluate(Expression(list[1]), environment: env).value as? Bool {
					let toEvaluate = condition ? list[2] : list[3]
					return try evaluate(Expression(toEvaluate), environment: env)
				} else {
					throw LispError.evaluationError(message: "\(list[1]) could not be evaluated as a boolean value")
				}
			} else if firstSymbol == "define" {
				guard list.count == 3 else {
					throw LispError.incorrectArgumentCount(shouldBe: 2)
				}
				guard list[1] is Symbol else {
					throw LispError.typeError(message: "Expected a symbol, but got \(list[1])")
				}
				
				let symbol = list[1] as! Symbol
				if let _ = Expression(list[2]).value {
					let evaluated = try evaluate(Expression(list[2]), environment: env)
					env.symbols[symbol] = { (_ array: List) -> Expression in
						if let closure = evaluated.value as? LispClosure {
							return try closure(array)
						}
						return evaluated
					}
					return Expression(env.symbols[symbol]!)
				} else {
					throw LispError.typeError(message: "Expected an expression")
				}
			} else if firstSymbol == "set!" {
				guard list.count == 3 else {
					throw LispError.incorrectArgumentCount(shouldBe: 2)
				}
				guard list[1] is Symbol else {
					throw LispError.typeError(message: "Expected a symbol, but got \(list[1])")
				}
				
				let symbol = list[1] as! Symbol
				if let _ = Expression(list[2]).value {
					let evaluated = try evaluate(Expression(list[2]), environment: env)
					try env.find(symbol: symbol)!.symbols[symbol] = { (_ array: List) -> Expression in
						if let closure = evaluated.value as? LispClosure {
							return try closure(array)
						}
						return evaluated
					}
					return try Expression(env.find(symbol: symbol)!.symbols[symbol]!)
				} else {
					throw LispError.typeError(message: "Expected an expression")
				}
			} else if firstSymbol == "quote" {
				guard list.count == 2 else {
					throw LispError.incorrectArgumentCount(shouldBe: 1)
				}
				return try evaluate(Expression(list[1]), environment: env, quote: true)
			} else if firstSymbol == "lambda" {
				guard list.count == 3 else {
					throw LispError.incorrectArgumentCount(shouldBe: 2)
				}
				guard Expression(list[1]).value is List else {
					throw LispError.typeError(message: "Expected a list, but got \(list[1])")
				}
				//				guard list[2] is Expression else {
				//					throw LispError.typeError(message: "Expected an expression")
				//				}
				let closure = { (_ clist: List) -> Expression in
					guard clist.count > 0 else {
						throw LispMessage.typeDescription("Closure")
					}
					return try Procedure(params: Expression(list[1]).value as! [Symbol], bdy: Expression(list[2]), env: env).call(with: Array(clist[1..<clist.count]), env: env)
				}
				return Expression(closure)
			} else if firstSymbol == "begin" {
				guard list.count >= 2 else {
					throw LispError.tooFewArguments(shouldBeAtLeast: 1)
				}
				var toReturn: Expression!
				for expression in list[1..<list.count] {
					toReturn = try evaluate(Expression(expression), environment: env)
				}
				return toReturn
			} else {
				if let proc = try env.find(symbol: firstSymbol)!.symbols[firstSymbol] {
					let args = list
					let arguments = try args[1..<args.count].map { try evaluate(Expression($0), environment: env).value! }
					return try proc([list[0]] + arguments)
				} else {
					throw LispError.undefinedError(message: "\(firstSymbol) is not a symbol")
				}
			}
		} else if list.first is Number {
			return Expression(list)
		} else {
			do {
				let evaluatedList = try list.map{ try evaluate(Expression($0), environment: env) }
				return Expression(evaluatedList)
			} catch {
				throw LispError.evaluationError(message: "\(list[0]) is not a symbol")
			}
			
		}
	} else {
		if let value = exp.value {
			if let closure = value as? LispClosure {
				return Expression(closure)
			}
			let atom = Atom(value)
			//Variable Reference
			if atom.type == .symbol {
				let symbol = atom.value as! Symbol
				//String
				if symbol.hasPrefix("\"") && symbol.hasSuffix("\"") {
					return Expression(symbol)
				}
				//Symbol
				do {
					return try env.find(symbol: symbol)!.getExpressionFor(symbol: symbol)
				} catch LispError.undefinedError(let message) {
					throw LispError.undefinedError(message: message)
				}
			} else if let number = atom.value as? Number {
				//Number
				return Expression(number)
			} else {
				return Expression(atom)
			}
		} else {
			throw LispError.evaluationError(message: "\(exp) could not be evaluated")
		}
	}
	
}

func eval(lists: List, environment: Environment) -> [Any] {
	var outputs: [String] = []
	for list in lists {
		do {
			try outputs.append(evaluate(Expression(list), environment: environment).description)
		} catch LispError.evaluationError(let messsage) {
			outputs.append(messsage)
		} catch LispError.incorrectArgumentCount(let numberOfArguments) {
			outputs.append("Incorrect number of arguments. Should have \(numberOfArguments) argument" + (numberOfArguments == 1 ? "" : "s"))
		} catch LispError.tooFewArguments(let minimumNumberOfArguments) {
			outputs.append("Too few arguments. Should have at least \(minimumNumberOfArguments) argument" + (minimumNumberOfArguments == 1 ? "" : "s"))
		} catch LispError.noCar {
			outputs.append("No car")
		} catch LispError.typeError(let message) {
			outputs.append(message)
		} catch LispMessage.typeDescription(let description) {
			outputs.append("#<\(description)>")
		} catch LispError.undefinedError(let message) {
			outputs.append(message)
		} catch {
			outputs.append("Error")
		}
	}
	for i in 0..<outputs.count {
		outputs[i] = outputs[i].replacingOccurrences(of: "[", with: "(").replacingOccurrences(of: "]", with: ")").replacingOccurrences(of: ", ", with: " ")
	}
	return outputs
}
