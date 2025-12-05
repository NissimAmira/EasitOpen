//
//  AlertState.swift
//  EasitOpen
//
//  Created by nissim amira on 05/12/2025.
//

import Foundation

struct AlertState: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let primaryButton: AlertButton?
    let secondaryButton: AlertButton?
    
    struct AlertButton {
        let title: String
        let action: () -> Void
    }
    
    init(
        title: String,
        message: String,
        primaryButton: AlertButton? = nil,
        secondaryButton: AlertButton? = nil
    ) {
        self.title = title
        self.message = message
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
    }
}
