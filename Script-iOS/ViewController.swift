//
//  ViewController.swift
//  Script-iOS
//
//  Created by Izumu Mishima on 13/07/2016.
//  Copyright © 2016 Izumu Mishima. All rights reserved.
//

import UIKit
import JavaScriptCore

class ViewController: UIViewController, UITextFieldDelegate {
	
	let fontSize: CGFloat = 14
	@IBOutlet var textView: UITextView!
	@IBOutlet var textField: UITextField!
	@IBOutlet var bottomLayout: NSLayoutConstraint!
	@IBOutlet var textViewTopLayout: NSLayoutConstraint!
	@IBOutlet var topBar: UIView!
	
	var textVText: NSMutableAttributedString = NSMutableAttributedString(string: "")
	let jsContext = JSContext()
	var topInset: CGFloat = 0
	let margin: CGFloat = 8
	
	override func viewDidLoad() {
		super.viewDidLoad()
		textField.delegate = self
		textView.attributedText = AttributedString(string: "")
		let notificationCenter = NotificationCenter.default()
		notificationCenter.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil);
		notificationCenter.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil);
		view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard)))
		setNeedsStatusBarAppearanceUpdate()
		textField.font = UIFont(name: "SFMono-Regular", size: fontSize + 2)
		textField.textColor = UIColor.white()
		textField.backgroundColor = UIColor(white: 0.5, alpha: 0.25)
		
		let placeholder = AttributedString(string: ">", attributes: [NSFontAttributeName: UIFont(name: "SFMono-Medium", size: (textField.font?.pointSize)!)!,NSForegroundColorAttributeName: UIColor(white: 1, alpha: 0.3)  ])
		textField.attributedPlaceholder = placeholder
		
		
		_ = jsContext?.evaluateScript("var console = { log: function(message) { _consoleLog(message) } }")
		_ = jsContext?.evaluateScript("const print = function(message) { return console.log(message) }")
		let consoleLog: @convention(block) (String) -> Void = { message in
			self.printToScreen(message: message)
		}
		jsContext?.setObject(unsafeBitCast(consoleLog, to: AnyObject.self), forKeyedSubscript: "_consoleLog")
		addMaths(jsContext: jsContext)
		/*
		_ = jsContext?.evaluateScript("const pi = Math.PI")
		_ = jsContext?.evaluateScript("const e = Math.E")
		_ = jsContext?.evaluateScript("const abs = function(x) {\n\treturn Math.abs(x)\n}")
		_ = jsContext?.evaluateScript("const ceil = function(x) {\n\treturn Math.ceil(x)\n}")
		_ = jsContext?.evaluateScript("const exp = function(x) {\n\treturn Math.exp(x)\n}")
		_ = jsContext?.evaluateScript("const floor = function(x) {\n\treturn Math.floor(x)\n}")
		_ = jsContext?.evaluateScript("const log = function(x) {\n\treturn Math.log(x)\n}")
		_ = jsContext?.evaluateScript("const pow = function(x, y) {\n\treturn Math.pow(x, y)\n}")
		_ = jsContext?.evaluateScript("const random = function(x) {\n\treturn Math.random(x)\n}")
		_ = jsContext?.evaluateScript("const round = function(x) {\n\treturn Math.round(x)\n}")
		_ = jsContext?.evaluateScript("const sqrt = function(x) {\nr\teturn Math.sqrt(x)\n}")
		
		_ = jsContext?.evaluateScript("const sin = function(deg) {\n\treturn Math.sin(deg * pi / 180)\n}")
		_ = jsContext?.evaluateScript("const cos = function(deg) {\n\treturn Math.cos(deg * pi / 180)\n}")
		_ = jsContext?.evaluateScript("const tan = function(deg) {\n\treturn Math.tan(deg * pi/ 180)\n}")
		_ = jsContext?.evaluateScript("const asin = functionx) {\n\treturn Math.asin(x) * 180 / pi\n}")
		_ = jsContext?.evaluateScript("const acos = function(x) {\n\treturn Math.acos(x) * 180 / pi\n}")
		_ = jsContext?.evaluateScript("const atan = function(x) {\n\treturn Math.atan(x) * 180 / pi\n}")
		_ = jsContext?.evaluateScript("const atan2 = function(x, y) {\n\treturn Math.atan2(x,y) * 180 / pi\n}")*/
	}
	
	override func viewDidAppear(_ animated: Bool) {
		topInset = topBar.frame.height
		textView.contentInset.top = topInset
		textView.scrollIndicatorInsets.top = topInset
		textView.isScrollEnabled = false
		textView.isScrollEnabled = true
	}
	
	func dismissKeyboard() {
		textField.resignFirstResponder()
	}
	
	func scrollToBottom() {
		let end = NSMakeRange(textView.attributedText.length - 1, 1);
		textView.scrollRangeToVisible(end)
	}
	
	func animateTextField(duration: TimeInterval, curve: UInt, constant: CGFloat) {
		UIView.animate(withDuration: duration, delay: 0, options: UIViewAnimationOptions(rawValue: curve), animations: {
			self.bottomLayout.constant = constant
			self.textViewTopLayout.constant = -20 - (constant - self.margin)
			self.textView.contentInset.top = self.topInset + (constant - self.margin)
			self.textView.scrollIndicatorInsets.top = self.topInset + (constant - self.margin)
			self.view.layoutIfNeeded()
			}, completion: nil)
	}
	
	func keyboardWillShow(notification: NSNotification) {
		let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
		let curve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as! UInt
		if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue() {
			let dY = keyboardSize.height
			animateTextField(duration: duration, curve: curve, constant: dY + margin)
		}
		scrollToBottom()
	}
	func keyboardWillHide(notification: NSNotification) {
		let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
		let curve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as! UInt
		animateTextField(duration: duration, curve: curve, constant: margin)
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if !(textField.text?.isEmpty)! {
			var charArr: [Character] = []
			for char in (textField.text?.characters)! {
				charArr.append(char)
			}
			for i in 0..<charArr.count {
				if charArr[i] != " " {
					break
				} else if i == charArr.count - 1 {
					textField.text = ""
					return true
				}
			}
			let font = [NSFontAttributeName: UIFont(name: "SFMono-Medium", size: fontSize)!, NSForegroundColorAttributeName: UIColor.white()]
			let text = AttributedString(string: textField.text!, attributes: font)
			textVText.append(text)
			textVText.append(AttributedString(string: "\n"))
			let msgFont = [NSFontAttributeName: UIFont(name: "SFMono-Regular", size: fontSize)!, NSForegroundColorAttributeName: UIColor.lightText()]
			let msgText = AttributedString(string: jsEval(script: textField.text!, context: jsContext!).msg, attributes: msgFont)
			
			textVText.append(msgText)
			textVText.append(AttributedString(string: msgText == AttributedString("") ? "" : "\n"))
			textView.attributedText = textVText as AttributedString
			
			scrollToBottom()
			
			textField.text = ""
		}
		return true
	}
	
	func moveCursor(offset: Int) {
		let newCursorPosition = textField.position(from: (textField.selectedTextRange?.start)!, offset: offset)
		let newSelectedRange = textField.textRange(from: newCursorPosition!, to:newCursorPosition!)
		textField.selectedTextRange = newSelectedRange
	}
	
	func printToScreen(message: String) {
		let msgFont = [NSFontAttributeName: UIFont(name: "SFMono-Regular", size: fontSize)!, NSForegroundColorAttributeName: UIColor.lightText()]
		let msgText = AttributedString(string: message, attributes: msgFont)
		textVText.append(msgText)
		textVText.append(AttributedString(string: "\n"))
		textView.attributedText = textVText as AttributedString
	}
	
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		switch string {
		case "{":
			textField.insertText("}")
			moveCursor(offset: -1)
		case "(":
			textField.insertText(")")
			moveCursor(offset: -1)
		case "[":
			textField.insertText("]")
			moveCursor(offset: -1)
		case "\"":
			textField.insertText("\"")
			moveCursor(offset: -1)
		default:
			break
		}
		return true
	}
	
	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.lightContent
	}
}

