import SwiftUI

public struct CheckboxView: View {

    @Binding var isChecked: Bool
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorTheme) var colorTheme
    
    public init(isChecked: Binding<Bool>) {
        _isChecked = isChecked
    }

    public var body: some View {
        if isChecked {
            Image(systemName: "checkmark")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.white)
                .padding(6)
                .background {
                    shapeBackground
                }
        } else {
            shapeBackground
        }
    }
    
    private var shapeBackground: some View {
        Group {
            if appTheme.cornerRadius > 0 {
                Circle()
                    .strokeBorder(isChecked ? colorTheme.getColor(.accent) : Color.gray, lineWidth: 1.5)
                    .background(isChecked ? Circle().fill(colorTheme.getColor(.accent)) : nil)
            } else {
                Rectangle()
                    .strokeBorder(isChecked ? colorTheme.getColor(.accent) : Color.gray, lineWidth: 1.5)
                    .background(isChecked ? Rectangle().fill(colorTheme.getColor(.accent)) : nil)
            }
        }
        .foregroundStyle(isChecked ? .accent : .text)
    }
}

struct CheckboxView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CheckboxView(isChecked: .constant(true))
            CheckboxView(isChecked: .constant(false))
        }
        .previewLayout(.fixed(width: 20, height: 20))
    }
}
