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

func appendMessage(message: String) {
	if message != "" {
		let msgFont = [NSFontAttributeName: NSFont(name: "SFMono-Regular", size: fontSize)!, NSForegroundColorAttributeName: NSColor.white()]
		let msgText = AttributedString(string: message, attributes: msgFont)
		textVText.append(msgText)
		textVText.append(AttributedString(string: "\n"))
	}
}

class ViewController: NSViewController, NSTextViewDelegate {
	
	@IBOutlet var textView: NSTextView!
	@IBOutlet var textField: NSTextField!
	@IBOutlet var inputTextView: NSTextView!
	
	var braceLevel: Int = 0
	
	//	var textVText: NSMutableAttributedString = NSMutableAttributedString(string: "")
	let jsContext = JSContext()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.window?.backgroundColor = NSColor.clear()
		self.view.layer?.backgroundColor = NSColor.clear().cgColor
		
		NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (aEvent) -> NSEvent? in
			self.keyDown(aEvent)
			return aEvent
		}
		
		NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { (theEvent) -> NSEvent? in
			self.flagsChanged(theEvent)
			return theEvent
		}
		
		inputTextView.delegate = self
		inputTextView.frame = NSRect(x: inputTextView.frame.minX, y: inputTextView.frame.minY, width: inputTextView.frame.width, height: 22)
		
		textView.textStorage?.setAttributedString(AttributedString(string: ""))
		
		inputTextView.font = NSFont(name: "SFMono-Regular", size: fontSize + 2)
		inputTextView.textColor = NSColor.white()
		inputTextView.backgroundColor = NSColor(white: 0, alpha: 0.25)
		inputTextView.isAutomaticQuoteSubstitutionEnabled = false
		braceLevel = 0
		
		addMaths(jsContext: jsContext!)
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
	
	override func keyDown(_ theEvent:NSEvent) {
		if theEvent.keyCode == 36 && theEvent.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command {
			_ = jsEntered()
		} else if theEvent.keyCode == 76 && theEvent.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command {
			_ = jsEntered()
		}
	}
	
	func textShouldEndEditing(_ textObject: NSText) -> Bool {
		return jsEntered()
	}
	
	func moveCursor(offset: Int) {
		let newCursorPosition = inputTextView.selectedRanges[0].rangeValue
		inputTextView.setSelectedRange(NSMakeRange(newCursorPosition.location + offset, 0))
	}
	
	func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
		switch replacementString! {
		case "{":
			inputTextView.replaceCharacters(in: inputTextView.selectedRanges[0].rangeValue, with: "{}")
			moveCursor(offset: -1)
			return false
		case "(":
			inputTextView.replaceCharacters(in: inputTextView.selectedRanges[0].rangeValue, with: "()")
			moveCursor(offset: -1)
			return false
		case "[":
			inputTextView.replaceCharacters(in: inputTextView.selectedRanges[0].rangeValue, with: "[]")
			moveCursor(offset: -1)
			return false
		case "\"":
			inputTextView.replaceCharacters(in: inputTextView.selectedRanges[0].rangeValue, with: "\"\"")
			moveCursor(offset: -1)
			return false
		case "\n":
			braceLevel = 0
			for i in 0..<inputTextView.selectedRanges[0].rangeValue.location {
				let index = inputTextView.string!.index((inputTextView.string!.startIndex), offsetBy: i)
				let c = String(inputTextView.string!.characters[index...index])
				if c == "{" {
					braceLevel += 1
				} else if c == "}" {
					braceLevel -= 1
				}
			}
			var indents = ""
			if braceLevel > 0 {
				for _ in 0..<braceLevel {
					indents += "\t"
				}
			}
			
			defer {
				inputTextView.replaceCharacters(in: inputTextView.selectedRanges[0].rangeValue, with: "\n" + indents)
			}
			let indx = inputTextView.string!.index(inputTextView.string!.startIndex, offsetBy: inputTextView.selectedRanges[0].rangeValue.location)
			if inputTextView.string!.endIndex != indx && indx != inputTextView.string!.startIndex {
				let a = inputTextView.string!.index(inputTextView.string!.startIndex, offsetBy: inputTextView.selectedRanges[0].rangeValue.location)
				let b = inputTextView.string!.index(inputTextView.string!.startIndex, offsetBy: inputTextView.selectedRanges[0].rangeValue.location - 1)
				let before = String(inputTextView.string!.characters[b...b])
				let after = String(inputTextView.string!.characters[a...a])
				if before == "{" && after == "}" {
					var indents2 = ""
					if braceLevel > 1 {
						for _ in 1..<braceLevel {
							indents2 += "\t"
						}
					}
					defer {
						inputTextView.replaceCharacters(in: inputTextView.selectedRanges[0].rangeValue, with: "\n" + indents2)
						for _ in 0..<braceLevel {
							moveCursor(offset: -1)
						}
					}
				}
			}
			return false
		default:
			break
		}
		
		
		return true
	}
	
	func jsEntered() -> Bool {
		if !(inputTextView.string?.isEmpty)! {
			var charArr: [Character] = []
			for char in (inputTextView.string?.characters)! {
				charArr.append(char)
			}
			for i in 0..<charArr.count {
				if charArr[i] != " " {
					break
				} else if i == charArr.count - 1 {
					inputTextView.string = ""
					return true
				}
			}
			let font = [NSFontAttributeName: NSFont(name: "SFMono-Bold", size: fontSize + 2)!, NSForegroundColorAttributeName: NSColor.white()]
			let text = AttributedString(string: inputTextView.string!, attributes: font)
			textVText.append(text)
			textVText.append(AttributedString(string: "\n"))
			_ = jsEval(script: inputTextView.string!, context: jsContext!)
			
			textView.textStorage?.setAttributedString(textVText as AttributedString)
			
			scrollToBottom()
			
			inputTextView.string = ""
		}
		return true
	}
}

