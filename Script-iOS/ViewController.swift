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

class ViewController: UIViewController, UITextViewDelegate {
	
	@IBOutlet var outputTextView: UITextView!
	@IBOutlet var inputTextView: UITextView!
	@IBOutlet var topBar: UIView!
	@IBOutlet var bottomLayoutConstraint: NSLayoutConstraint!
	@IBOutlet var inputTextViewHeight: NSLayoutConstraint!
	@IBOutlet var enterButton: UIButton!
	
	let jsContext = JSContext()
	var topInset: CGFloat = 0
	let margin: CGFloat = 8
	
	let placeholderColour = UIColor(white: 1, alpha: 0.5)
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if inputColour != .white {
			view.tintColor = inputColour
		}
		inputTextView.delegate = self
		outputTextView.attributedText = NSAttributedString(string: "")
		let notificationCenter = NotificationCenter.default
		notificationCenter.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil);
		notificationCenter.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil);
		view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard)))
		setNeedsStatusBarAppearanceUpdate()
		inputTextView.font = UIFont(name: normalFontName, size: fontSize + 2)
		inputTextView.textColor = placeholderColour
		inputTextView.backgroundColor = UIColor(white: 0.5, alpha: 0.25)
		enterButton.backgroundColor = inputTextView.backgroundColor
		
//		let placeholder = NSAttributedString(string: ">", attributes: [NSFontAttributeName: UIFont(name: "SFMono-Bold", size: (inputTextView.font?.pointSize)!)!,NSForegroundColorAttributeName: UIColor(white: 1, alpha: 0.3)  ])
//		inputTextView.attributedPlaceholder = placeholder
		addMaths(jsContext: jsContext!)
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
	
	func dismissKeyboard() {
		inputTextView.resignFirstResponder()
	}
	
	func scrollToBottom(_ textView: UITextView) {
		let end = NSMakeRange(textView.attributedText.length - 1, 1);
		textView.scrollRangeToVisible(end)
	}
	
	func animateTextView(duration: TimeInterval, curve: UInt, constant: CGFloat) {
		UIView.animate(withDuration: duration, delay: 0, options: UIViewAnimationOptions(rawValue: curve), animations: {
			self.bottomLayoutConstraint.constant = constant
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
			animateTextView(duration: duration, curve: curve, constant: dY + margin)
		}
		scrollToBottom(outputTextView)
	}
	
	func keyboardWillHide(notification: NSNotification) {
		let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
		let curve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as! UInt
		animateTextView(duration: duration, curve: curve, constant: margin)
	}
	
	func textViewShouldReturn(_ textView: UITextView) -> Bool {
		return jsEntered()
	}
	@IBAction func enterButtonPressed(_ sender: Any) {
		_ = jsEntered()
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
			let font = [NSFontAttributeName: UIFont(name: normalFontName, size: fontSize)!, NSForegroundColorAttributeName: inputColour]
			let text = NSAttributedString(string: "> " + inputTextView.text!, attributes: font)
			textVText.append(text)
			textVText.append(NSAttributedString(string: "\n"))
			
			_ = jsEval(script: inputTextView.text!, context: jsContext!)
			
			outputTextView.attributedText = textVText as NSAttributedString
			
			scrollToBottom(outputTextView)
			
			inputTextView.text = ""
			
			updateInputTextViewHeight()
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
		switch text {
		case "{":
			textView.insertText("}")
			moveCursor(offset: -1)
		case "(":
			textView.insertText(")")
			moveCursor(offset: -1)
		case "[":
			textView.insertText("]")
			moveCursor(offset: -1)
		case "\"":
			textView.insertText("\"")
			moveCursor(offset: -1)
		case "\n":
			if let characterBeforeCursor = characterBeforeCursor() {
				if characterBeforeCursor == "{" {
					textView.insertText("    \n")
					moveCursor(offset: -1)
				}
			}
		default:
			break
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
	
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return UIStatusBarStyle.lightContent
	}
}

