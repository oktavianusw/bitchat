//
//  SectionHeader.swift
//  bitchat_iOS
//
//  Created by Saputra on 19/08/25.
//

import SwiftUI

struct SectionHeaderView: View {
    let title: String
    let textStyle: Font.TextStyle
    
    init(title: String, textStyle: Font.TextStyle = .largeTitle) {
        self.title = title
        self.textStyle = textStyle
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(textStyle))
                .bold()
                .foregroundStyle(Color.textHeader)
                .accessibilityAddTraits(.isHeader)
            Spacer()
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        SectionHeaderView(title: "Near You")
        SectionHeaderView(
                    title: "Chats")
    }
    .padding(.horizontal, 20)
}
