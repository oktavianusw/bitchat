//
//  EditableCircleAvatar.swift
//  bitchat
//
//  Created by Saputra on 20/08/25.
//

import SwiftUI

struct EditableCircleAvatar: View {
    var image: Image? = nil
    var diameter: CGFloat = 84
    var onEdit: () -> Void = {}
    @Binding var color: Color

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(Color(.systemGray6))
                .frame(width: diameter, height: diameter)
                .overlay(
                    Group {
                        if let image { image.resizable().scaledToFill() }
                        else { Circle().fill(color).frame(width: diameter, height: diameter) }
                    }
                    .foregroundStyle(.secondary)
//                    .clipShape(Circle())
                )
                .overlay(Circle().stroke(Color.background, lineWidth: 8))

            Button(action: onEdit) {
                Image("union")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)
                    .padding(6)
                    .background(Circle().fill(Color.black.opacity(0.6)))
                    .overlay(Circle().stroke(Color.background, lineWidth: 2))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    EditableCircleAvatar(color: .constant(.blue))
}
