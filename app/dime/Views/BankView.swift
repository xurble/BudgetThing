//
//  BankView.swift
//  dime
//
//  Created by Gareth Simpson on 7/3/2026
//

import SwiftUI

struct BankView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "banknote")
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .foregroundColor(Color.PrimaryText)

            Text("Bank")
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .foregroundColor(Color.PrimaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .liquidGlassBackground()
    }
}

#Preview {
    BankView()
}
