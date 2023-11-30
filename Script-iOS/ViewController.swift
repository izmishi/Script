//
//  ViewController.swift
//  Script-iOS
//
//  Created by Izumu Mishima on 13/07/2016.
//  Copyright © 2016 Izumu Mishima. All rights reserved.
//

import UIKit
import JavaScriptCore

let orange = UIColor(red: 1, green: 80.0/255, blue: 0, alpha: 1)

let inputColour = UIColor.white
let printColour = UIColor(white: 0.6, alpha: 1)
let outputColour = UIColor(red: 0, green: 0.7, blue: 0.7, alpha: 1)

let normalFontName = "SFMono-Medium"

func appendMessage(message: String, print: Bool = false) {
	if message != "" {
		let stringToAppend = message
		let msgColour = print ? printColour : outputColour
		let fontName = print ? normalFontName : "SFMono-Bold"
		let msgFont = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: fontName, size: fontSize)!, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): msgColour]
		let msgText = NSAttributedString(string: stringToAppend, attributes: convertToOptionalNSAttributedStringKeyDictionary(msgFont))
		textVText.append(msgText)
		textVText.append(NSAttributedString(string: "\n"))
	}
}

enum Language {
	case javascript
	case lisp
}


class ViewController: UIViewController, UITextViewDelegate {
	
	@IBOutlet var outputTextView: UITextView!
	@IBOutlet var inputTextView: UITextView!
	@IBOutlet var topBar: UIView!
	@IBOutlet var bottomLayoutConstraint: NSLayoutConstraint!
	@IBOutlet var inputTextViewHeight: NSLayoutConstraint!
	@IBOutlet var enterButton: UIButton!
	@IBOutlet var languageButton: UIButton!
	
	let jsContext = JSContext()
	var lispGlobalEnvironment = Environment()
	var topInset: CGFloat = 0
	let margin: CGFloat = 8
	
	let placeholderColour = UIColor(white: 1, alpha: 0.5)
	
	var lastEnteredCharacter: String = ""
	
	var language: Language = .lisp
	var tintColours: [Language: UIColor] = [.lisp: .white, .javascript: orange]
	
	var languageOutputTexts: [Language: NSMutableAttributedString] = [.lisp: NSMutableAttributedString(string: ""), .javascript: NSMutableAttributedString(string: "")]
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.tintColor = tintColours[language]
		languageButton.setTitle(language == .javascript ? "Javascript" : "Lisp", for: .normal)
		
		inputTextView.delegate = self
		outputTextView.attributedText = NSAttributedString(string: "")
		let notificationCenter = NotificationCenter.default
		notificationCenter.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		notificationCenter.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
		outputTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard)))
		setNeedsStatusBarAppearanceUpdate()
		inputTextView.font = UIFont(name: normalFontName, size: fontSize + 2)
		inputTextView.textColor = placeholderColour
		inputTextView.backgroundColor = UIColor(white: 0.5, alpha: 0.25)
		enterButton.backgroundColor = inputTextView.backgroundColor
		
		addMaths(jsContext: jsContext!)
		evaluateLisp(input: builtInLisp, output: false)
	}
	
	override func viewDidAppear(_ animated: Bool) {
//		topInset = topBar.frame.height
		outputTextView.contentInset.top = topInset
		outputTextView.scrollIndicatorInsets.top = topInset
		outputTextView.isScrollEnabled = false
		outputTextView.isScrollEnabled = true
		
		updateInputTextViewHeight()
		
		print(inputTextView.frame)
	}
	
	@objc func dismissKeyboard() {
		inputTextView.resignFirstResponder()
	}
	
	func scrollToBottom(_ textView: UITextView) {
		let end = NSMakeRange(textView.attributedText.length - 1, 1);
		textView.scrollRangeToVisible(end)
	}
	
	func animateTextView(duration: TimeInterval, curve: UInt, constant: CGFloat) {
		UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
			self.bottomLayoutConstraint.constant = constant
//			self.textViewTopLayout.constant = -20 - (constant - self.margin)
//			self.textView.contentInset.top = self.topInset + (constant - self.margin)
//			self.textView.scrollIndicatorInsets.top = self.topInset + (constant - self.margin)
			self.view.layoutIfNeeded()
			}, completion: nil)
	}
	
	@objc func keyboardWillShow(notification: NSNotification) {
		let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
		let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as! UInt
		if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
			let dY = keyboardSize.height
			animateTextView(duration: duration, curve: curve, constant: dY + margin)
		}
		scrollToBottom(outputTextView)
	}
	
	@objc func keyboardWillHide(notification: NSNotification) {
		let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
		let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as! UInt
		animateTextView(duration: duration, curve: curve, constant: margin)
	}
	
	func textViewShouldReturn(_ textView: UITextView) -> Bool {
		return evaluateInput()
	}
	@IBAction func enterButtonPressed(_ sender: Any) {
		_ = evaluateInput()
	}
	@IBAction func languageButtonPressed(_ sender: Any) {
		UIView.setAnimationsEnabled(false)
		if language == .javascript {
			languageOutputTexts[.javascript] = textVText
			textVText = languageOutputTexts[.lisp]!
			language = .lisp
			languageButton.setTitle("Lisp", for: .normal)
		} else {
			languageOutputTexts[.lisp] = textVText
			textVText = languageOutputTexts[.javascript]!
			language = .javascript
			languageButton.setTitle("Javascript", for: .normal)
		}
		view.tintColor = tintColours[language]
		UIView.setAnimationsEnabled(true)
		outputTextView.attributedText = textVText as NSAttributedString
		scrollToBottom(outputTextView)
	}
	
	func evaluateInput() -> Bool {
		if let input = inputTextView.text {
			guard !input.isEmpty else {
				return true
			}
			guard inputTextView.isFirstResponder else {
				return true
			}
			addInputToTextView()
			switch language {
			case .javascript:
				_ = jsEntered()
			case .lisp:
				evaluateLisp(input: input)
			}
			
			outputTextView.attributedText = textVText as NSAttributedString
			scrollToBottom(outputTextView)
			inputTextView.text = ""
			updateInputTextViewHeight()
		}
		return true
	}
	
	func addInputToTextView() {
		let font = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: normalFontName, size: fontSize)!, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): inputColour]
		var string = "> " + inputTextView.text!
		if outputTextView.text != "" {
			string = "\n" + string
		}
		let text = NSAttributedString(string: string, attributes: convertToOptionalNSAttributedStringKeyDictionary(font))
		textVText.append(text)
		textVText.append(NSAttributedString(string: "\n"))
	}
	
	func evaluateLisp(input: String, output: Bool = true) {
		do {
			let parsed = try parse(input)
			let evaluated = eval(lists: parsed.value as! List, environment: lispGlobalEnvironment)
			if !output {
				return
			}
			for output in evaluated {
				appendMessage(message: "\(output)")
			}
		} catch LispError.parseError {
			appendMessage(message: "Could not parse input")
		} catch {
			appendMessage(message: "Unknown Error")
		}
	}
	
	func jsEntered() -> Bool {
		if !(inputTextView.text?.isEmpty)! {
			var charArr: [Character] = []
			for char in inputTextView.text! {
				charArr.append(char)
			}
			for i in 0..<charArr.count {
				if charArr[i] != " " {
					break
				} else if i == charArr.count - 1 {
					inputTextView.text = ""
					return true
				}
			}
			
			_ = jsEval(script: inputTextView.text!, context: jsContext!)
		}
		return true
	}
	func moveCursor(offset: Int) {
		let newCursorPosition = inputTextView.position(from: (inputTextView.selectedTextRange?.start)!, offset: offset)
		let newSelectedRange = inputTextView.textRange(from: newCursorPosition!, to:newCursorPosition!)
		inputTextView.selectedTextRange = newSelectedRange
	}
	func textViewDidChange(_ textView: UITextView) {
		updateInputTextViewHeight()
	}
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
	
		defer {
			textView.isScrollEnabled = true
			updateInputTextViewHeight()
			lastEnteredCharacter = text
		}
		switch text {
		case "(":
			textView.insertText(")")
			moveCursor(offset: -1)
		case " ":
			if lastEnteredCharacter == " " {
				textView.insertText("  ")
			}
		case "\"":
			textView.insertText("\"")
			moveCursor(offset: -1)
		default:
			break
		}
		if language == .javascript {
			switch text {
			case "{":
				textView.insertText("}")
				moveCursor(offset: -1)
			case "[":
				textView.insertText("]")
				moveCursor(offset: -1)
			case "\'":
				textView.insertText("\'")
				moveCursor(offset: -1)
			case "\n":
				guard characterBeforeCursor() != nil else {
					return true
				}
				let characterBefore = characterBeforeCursor()!
				if characterBefore == "{" {
					textView.isScrollEnabled = false
					textView.insertText("\n")
					let indentationLevel = getIndentationLevel()
					for _ in 0..<indentationLevel{
						textView.insertText("    ") //4 spaces
					}
					textView.insertText("\n")
					for _ in 0..<indentationLevel - 1 {
						textView.insertText("    ") //4 spaces
					}
					moveCursor(offset: -1 - (4 * (indentationLevel - 1)))
					return false
				} else if ![";", "}", "\n"].contains(characterBefore){
					textView.insertText(";")
				}
				textView.insertText("\n")
				for _ in 0..<getIndentationLevel() {
					textView.insertText("    ") //4 spaces
				}
				return false
				
			default:
				break
			}
		}
		return true
	}
	
	func characterBeforeCursor() -> String? {
		
		// get the cursor position
		if let cursorRange = inputTextView.selectedTextRange {
			
			// get the position one character before the cursor start position
			if let newPosition = inputTextView.position(from: cursorRange.start, offset: -1) {
				
				let range = inputTextView.textRange(from: newPosition, to: cursorRange.start)
				return inputTextView.text(in: range!)
			}
		}
		return nil
	}
	
	func textViewDidBeginEditing(_ textView: UITextView) {
		if textView.textColor == placeholderColour {
			textView.text = nil
			textView.textColor = UIColor.white
		}
	}
	
	func textViewDidEndEditing(_ textView: UITextView) {
		if textView.text.isEmpty {
			textView.text = ">"
			textView.textColor = placeholderColour
		}
	}
	
	func updateInputTextViewHeight() {
		inputTextViewHeight.constant = min(inputTextView.contentSize.height, 207)
		view.layoutIfNeeded()
		scrollToBottom(outputTextView)
		if inputTextView.selectedTextRange?.end == inputTextView.endOfDocument {
			scrollToBottom(inputTextView)
		}
	}
	
	func getIndentationLevel() -> Int {
		var level: Int = 0
		
		let text = inputTextView.text(in: inputTextView.textRange(from: inputTextView.beginningOfDocument, to: (inputTextView.selectedTextRange?.start)!)!)!
		for character in text {
			if character == "{" {
				level += 1
			} else if character == "}" {
				level -= 1
			}
		}
		
		return max(0, level)
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return UIStatusBarStyle.lightContent
	}
	
	override var keyCommands: [UIKeyCommand]? {
		return [UIKeyCommand(input: "\r", modifierFlags: .command, action: #selector(enterButtonPressed(_:)), discoverabilityTitle: "Run Code"), UIKeyCommand(input: "\n", modifierFlags: .command, action: #selector(enterButtonPressed(_:)), discoverabilityTitle: "Run Code")]
	}
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
