//
//  View.swift
//  Bal
//
//  Created by Benjamin Baron on 6/7/16.
//  Copyright © 2016 Balanced Software, Inc. All rights reserved.
//

import AppKit

class View: NSView {
    var isClickingEnabled = true
    var isUserInteractionEnabled = true
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    fileprivate func commonInit() {
        self.wantsLayer = true
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        if isUserInteractionEnabled {
            return super.hitTest(point)
        }
        return nil
    }
    
    override func mouseDown(with event: NSEvent) {
        if isClickingEnabled {
            super.mouseDown(with: event)
        }
    }
}
