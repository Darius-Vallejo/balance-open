//
//  SecureField.swift
//  Bal
//
//  Created by Benjamin Baron on 6/7/16.
//  Copyright © 2016 Balanced Software, Inc. All rights reserved.
//

import AppKit

/// Secure text field with a clear background
class SecureField: NSSecureTextField {
    weak var customDelegate: TextFieldDelegate?
    
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
    
    override func becomeFirstResponder() -> Bool {
        customDelegate?.textFieldDidBecomeFirstResponder(self)
        return super.becomeFirstResponder()
    }
}
