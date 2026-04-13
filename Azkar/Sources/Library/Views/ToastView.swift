// Copyright © 2022 Al Jawziyya. All rights reserved.

import SwiftUI
import Popovers

struct ToastView: View {
    let message: String
    var icon: String?
    var tint: Color = .accentColor
    
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorTheme) var colorTheme
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(.title3).weight(.semibold))
                    .foregroundStyle(tint)
            }
            
            Text(message)
                .systemFont(.body, weight: .medium)
        }
        .applyContainerStyle()
    }
}

extension View {
    func showToast(message: String, icon: String?, tint: Color = .accentColor, isPresented: Bool) -> some View {
        self.modifier(ToastModifier(message: message, icon: icon, tint: tint, isPresented: isPresented))
    }
}

struct ToastModifier: ViewModifier {
    let message: String
    let icon: String?
    let tint: Color
    let isPresented: Bool
    
    func body(content: Content) -> some View {
        content.overlay {
            if isPresented {
                ToastView(message: message, icon: icon, tint: tint)
                    .transition(.opacity)
                    .animation(.easeInOut, value: isPresented)
            }
        }
    }
}

#Preview("Toast View") {
    VStack {
        ToastView(message: "Copied to clipboard!", icon: "doc.on.doc.fill")
        ToastView(message: "Image saved!", icon: "checkmark.circle.fill", tint: .green)
    }
}
