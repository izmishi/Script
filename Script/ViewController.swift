//
//  ViewController.swift
//  Script
//
//  Created by Izumu Mishima on 13/07/2016.
//  Copyright © 2016 Izumu Mishima. All rights reserved.
//

import Cocoa
import AppKit
import JavaScriptCore

class ViewController: NSViewController, NSTextFieldDelegate, NSTextViewDelegate {
	
	@IBOutlet var textView: NSTextView!
	@IBOutlet var textField: NSTextField!
	
	var textVText: NSMutableAttributedString = NSMutableAttributedString(string: "")
	let jsContext = JSContext()
	let fontSize: CGFloat = 14
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.window?.backgroundColor = NSColor.clear()
		self.view.layer?.backgroundColor = NSColor.clear().cgColor
		textField.delegate = self
		
		textView.textStorage?.setAttributedString(AttributedString(string: ""))
		textField.font = NSFont(name: "SFMono-Regular", size: fontSize + 2)
		textField.textColor = NSColor.white()
		textField.backgroundColor = NSColor(white: 0.5, alpha: 0.25)
		
		let placeholder = AttributedString(string: ">", attributes: [NSFontAttributeName: NSFont(name: "SFMono-Medium", size: (textField.font?.pointSize)!)!,NSForegroundColorAttributeName: NSColor(white: 1, alpha: 0.3)  ])
		textField.placeholderAttributedString = placeholder
		
		
		_ = jsContext?.evaluateScript("var console = { log: function(message) { _consoleLog(message) } }")
		_ = jsContext?.evaluateScript("const print = function(message) { return console.log(message) }")
		let consoleLog: @convention(block) (String) -> Void = { message in
			self.printToScreen(message: message)
		}
		jsContext?.setObject(unsafeBitCast(consoleLog, to: AnyObject.self), forKeyedSubscript: "_consoleLog")
		addMaths(jsContext: jsContext!)
	}

	func printToScreen(message: String) {
		let msgFont = [NSFontAttributeName: NSFont(name: "SFMono-Regular", size: fontSize)!, NSForegroundColorAttributeName: NSColor.white()]
		let msgText = AttributedString(string: message, attributes: msgFont)
		textVText.append(msgText)
		textVText.append(AttributedString(string: "\n"))
		textView.textStorage?.setAttributedString(textVText as AttributedString)
	}
	
	override var representedObject: AnyObject? {
		didSet {
		// Update the view, if already loaded.
		}
	}
	
	func scrollToBottom() {
		let end = NSMakeRange((textView.textStorage?.string.characters.count)! - 1 , 1);
		textView.scrollRangeToVisible(end)
	}

	func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
		if !textField.stringValue.isEmpty {
			var charArr: [Character] = []
			for char in textField.stringValue.characters {
				charArr.append(char)
			}
			for i in 0..<charArr.count {
				if charArr[i] != " " {
					break
				} else if i == charArr.count - 1 {
					textField.stringValue = ""
					return true
				}
			}
			let font = [NSFontAttributeName: NSFont(name: "SFMono-Bold", size: fontSize + 2)!, NSForegroundColorAttributeName: NSColor.white()]
			let text = AttributedString(string: textField.stringValue, attributes: font)
			textVText.append(text)
			textVText.append(AttributedString(string: "\n"))
			let msgFont = [NSFontAttributeName: NSFont(name: "SFMono-Regular", size: fontSize)!, NSForegroundColorAttributeName: NSColor.white()]
			let msgText = AttributedString(string: jsEval(script: textField.stringValue, context: jsContext!).msg, attributes: msgFont)
			
			textVText.append(msgText)
			textVText.append(AttributedString(string: msgText == AttributedString(string: "") ? "" : "\n"))
			textView.textStorage?.setAttributedString(textVText as AttributedString)
			
			scrollToBottom()
			
			textField.stringValue = ""
		}
		return true
	}

	
}

