//
//  ViewController.swift
//  Script
//
//  Created by Izumu Mishima on 13/07/2016.
//  Copyright © 2016 Izumu Mishima. All rights reserved.
//

import Cocoa
import AppKit

class ViewController: NSViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.window?.backgroundColor = NSColor.clear()
		self.view.layer?.backgroundColor = NSColor.clear().cgColor
		
		
		// Do any additional setup after loading the view.
	}

	override var representedObject: AnyObject? {
		didSet {
		// Update the view, if already loaded.
		}
	}


}

