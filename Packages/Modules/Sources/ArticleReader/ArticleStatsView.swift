import SwiftUI

private extension Text {
    @ViewBuilder
    func applyNumericTransition(_ number: Double) -> some View {
        if #available(iOS 17.0, *) {
            self
                .contentTransition(.numericText(value: number))
        } else if #available(iOS 16.0, *) {
            self
                .contentTransition(.numericText())
        } else {
            self
        }
    }
}

struct ArticleStatsView: View {
    
    let abbreviatedNumber: String
    let number: Int
    let imageName: String
    @State private var showNumber = false

    private var canShowPopover: Bool {
        number.description != abbreviatedNumber
    }

    private func togglePopover() {
        guard canShowPopover else { return }
        withAnimation(.spring) {
            showNumber.toggle()
        }
    }
    
    var body: some View {
        Button(action: togglePopover) {
            HStack {
                Image(systemName: imageName)
                    .accessibilityHidden(true)
                Text(abbreviatedNumber)
                    .applyNumericTransition(Double(number))
            }
        }
        .buttonStyle(.plain)
        .font(Font.caption)
        .accessibilityValue(Text(number.description))
        .disabled(canShowPopover == false)
        .popover(
            present: $showNumber,
            view: {
                Text(number.description)
                    .frame(minWidth: 20)
                    .padding(4)
                    .foregroundStyle(Color.secondary)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .opacity(showNumber ? 1 : 0)
            }
        )
    }
}

private struct StatsViewPreview: View {
    @State var number = 1
    
    var body: some View {
        VStack {
            Button("Increment", action: {
                withAnimation(.spring) {
                    number += 5
                }
            })
            
            ArticleStatsView(
                abbreviatedNumber: number.description,
                number: number,
                imageName: "eye"
            )
        }
    }
}

#Preview {
    StatsViewPreview()
}
