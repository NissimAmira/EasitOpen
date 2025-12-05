//
//  MessageType.swift
//  EasitOpen
//
//  Created by nissim amira on 05/12/2025.
//

import SwiftUI

enum MessageType {
    case success, info, warning, error
    
    var color: Color {
        switch self {
        case .success: return .green
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning, .error: return "exclamationmark.triangle.fill"
        }
    }
}
