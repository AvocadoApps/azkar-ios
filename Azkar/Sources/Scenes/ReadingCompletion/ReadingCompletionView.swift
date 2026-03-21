import SwiftUI
import Components

struct ReadingCompletionView: View {
    let isCompleted: Bool
    @Environment(\.colorTheme) var colorTheme
    let markAsCompleted: () async -> Void
    
    @State var isAnimating = false
    
    init(
        isCompleted: Bool,
        markAsCompleted: @escaping () async -> Void
    ) {
        self.isCompleted = isCompleted
        self.markAsCompleted = markAsCompleted
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if isCompleted {
                VStack {
                    if isAnimating {
                        LottieView(
                            name: "checkmark",
                            loopMode: .playOnce,
                            contentMode: .scaleAspectFit,
                            fillColor: colorTheme.getColor(.accent),
                            speed: 1,
                            progress: 0
                        )
                    } else {
                        Color.clear
                    }
                }
                .frame(width: 200, height: 200)
                
                Text(L10n.ReadingCompletion.title)
                    .systemFont(.title, weight: .bold)
                
                Text(L10n.ReadingCompletion.subtitle)
                    .systemFont(.body)
                    .foregroundColor(.secondary)
            } else {
                Text(L10n.ReadingCompletion.trackYourProgress)
                    .systemFont(.body)
                    .foregroundColor(colorTheme.getColor(.secondaryText))
                    .padding(.horizontal)
                
                Button(action: {
                    Task {
                        await markAsCompleted()
                    }
                }, label: {
                    Text(L10n.ReadingCompletion.markAsCompleted)
                        .systemFont(.body, weight: .semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(colorTheme.getColor(.accent))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                })
                .padding(.top, 8)
            }
        }
        .padding(30)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            isAnimating = true
        }
    }
    
}

struct ReadingCompletionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ReadingCompletionView(isCompleted: false, markAsCompleted: {})
                .previewDisplayName("Not Completed")
            ReadingCompletionView(isCompleted: true, markAsCompleted: {})
                .previewDisplayName("Completed")
        }
        .previewLayout(.sizeThatFits)
    }
}
