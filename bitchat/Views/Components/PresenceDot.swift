//
//  SwiftUIView.swift
//  bitchat
//
//  Created by Saputra on 22/08/25.
//

import SwiftUI

struct PresenceDot: View {
    var presence: Presence
    var size: CGFloat = 12
    
    private var color: Color {
        switch presence {
        case .inRange: return .gray
        case .outOfRange: return Color.brandPrimary
        case .unknown: return .clear
        }
    }
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .accessibilityHidden(true)
    }
}
