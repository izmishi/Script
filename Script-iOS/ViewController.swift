//
//  ViewController.swift
//  Script-iOS
//
//  Created by Izumu Mishima on 13/07/2016.
//  Copyright © 2016 Izumu Mishima. All rights reserved.
//

import UIKit
import JavaScriptCore

let inputColour = UIColor.white
let printColour = UIColor(white: 0.6, alpha: 1)
let outputColour = UIColor(red: 0, green: 0.7, blue: 0.7, alpha: 1)

let normalFontName = "SFMono-Medium"

func appendMessage(message: String, print: Bool = false) {
	if message != "" {
		let stringToAppend = message
		let msgColour = print ? printColour : outputColour
		let fontName = print ? normalFontName : "SFMono-Bold"
		let msgFont = [NSFontAttributeName: UIFont(name: fontName, size: fontSize)!, NSForegroundColorAttributeName: msgColour]
		let msgText = NSAttributedString(string: stringToAppend, attributes: msgFont)
		textVText.append(msgText)
		textVText.append(NSAttributedString(string: "\n"))
	}
}

class ViewController: UIViewController, UITextFieldDelegate {
	
	@IBOutlet var textView: UITextView!
	@IBOutlet var textField: UITextField!
	@IBOutlet var bottomLayout: NSLayoutConstraint!
	@IBOutlet var topBar: UIView!
	
	let jsContext = JSContext()
	var topInset: CGFloat = 0
	let margin: CGFloat = 8
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if inputColour != .white {
			view.tintColor = inputColour
		}
		textField.delegate = self
		textView.attributedText = NSAttributedString(string: "")
		let notificationCenter = NotificationCenter.default
		notificationCenter.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil);
		notificationCenter.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil);
		view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard)))
		setNeedsStatusBarAppearanceUpdate()
		textField.font = UIFont(name: normalFontName, size: fontSize + 2)
		textField.textColor = UIColor.white
		textField.backgroundColor = UIColor(white: 0.5, alpha: 0.25)
		
		let placeholder = NSAttributedString(string: ">", attributes: [NSFontAttributeName: UIFont(name: "SFMono-Bold", size: (textField.font?.pointSize)!)!,NSForegroundColorAttributeName: UIColor(white: 1, alpha: 0.3)  ])
		textField.attributedPlaceholder = placeholder
		addMaths(jsContext: jsContext!)
	}
	
	override func viewDidAppear(_ animated: Bool) {
//		topInset = topBar.frame.height
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
//			self.textViewTopLayout.constant = -20 - (constant - self.margin)
//			self.textView.contentInset.top = self.topInset + (constant - self.margin)
//			self.textView.scrollIndicatorInsets.top = self.topInset + (constant - self.margin)
			self.view.layoutIfNeeded()
			}, completion: nil)
	}
	
	func keyboardWillShow(notification: NSNotification) {
		let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
		let curve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as! UInt
		if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
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
		return jsEntered()
	}
	
	func jsEntered() -> Bool {
		if !(textField.text?.isEmpty)! {
			var charArr: [Character] = []
			for char in textField.text! {
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
			let font = [NSFontAttributeName: UIFont(name: normalFontName, size: fontSize)!, NSForegroundColorAttributeName: inputColour]
			let text = NSAttributedString(string: "> " + textField.text!, attributes: font)
			textVText.append(text)
			textVText.append(NSAttributedString(string: "\n"))
			
			_ = jsEval(script: textField.text!, context: jsContext!)
			
			textView.attributedText = textVText as NSAttributedString
			
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
	
	
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return UIStatusBarStyle.lightContent
	}
}

