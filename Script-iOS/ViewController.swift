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
	
	var textVText: NSMutableAttributedString = NSMutableAttributedString(string: "")
	let jsContext = JSContext()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		textField.delegate = self
		textView.attributedText = AttributedString(string: "")
		let notificationCenter = NotificationCenter.default()
		notificationCenter.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil);
		notificationCenter.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil);
		view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard)))
		setNeedsStatusBarAppearanceUpdate()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		self.textView.contentInset.top = 64
		self.textView.scrollIndicatorInsets.top = 64
	}
	
	func dismissKeyboard() {
		textField.resignFirstResponder()
	}
	
	func keyboardWillShow(notification: NSNotification) {
		let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
		let curve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as! UInt
		if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue() {
			let dY = keyboardSize.height
			UIView.animate(withDuration: duration, delay: 0, options: UIViewAnimationOptions(rawValue: curve), animations: {
				self.bottomLayout.constant = dY + 8
				}, completion: nil)
		}
	}
	func keyboardWillHide(notification: NSNotification) {
		let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
		let curve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as! UInt
		UIView.animate(withDuration: duration, delay: 0, options: UIViewAnimationOptions(rawValue: curve), animations: {
			self.bottomLayout.constant = 8
			}, completion: nil)
		
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		let font = [NSFontAttributeName: UIFont(name: "SFMono-Medium", size: fontSize)!, NSForegroundColorAttributeName: UIColor.white()]
		let text = AttributedString(string: textField.text!, attributes: font)
		let msgFont = [NSFontAttributeName: UIFont(name: "SFMono-Regular", size: fontSize)!, NSForegroundColorAttributeName: UIColor.lightText()]
		let msgText = AttributedString(string: jsEval(script: textField.text!, context: jsContext!).msg, attributes: msgFont)
		
		textVText.append(text)
		textVText.append(AttributedString(string: "\n"))
		textVText.append(msgText)
		textVText.append(AttributedString(string: "\n"))
		textView.attributedText = textVText as AttributedString
		
		textField.text = ""
		return true
	}
	
	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.lightContent
	}
}

