import SwiftUI
import Components

struct ReadingCompletionView: View {
    let isCompleted: Bool
    let hasUncompletedAzkar: Bool
    @Environment(\.colorTheme) var colorTheme
    let markAsCompleted: () async -> Void
    let goToFirstUncompleted: () -> Void

    @State var isAnimating = false

    init(
        isCompleted: Bool,
        hasUncompletedAzkar: Bool,
        markAsCompleted: @escaping () async -> Void,
        goToFirstUncompleted: @escaping () -> Void
    ) {
        self.isCompleted = isCompleted
        self.hasUncompletedAzkar = hasUncompletedAzkar
        self.markAsCompleted = markAsCompleted
        self.goToFirstUncompleted = goToFirstUncompleted
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
                
                Text("reading_completion.title")
                    .systemFont(.title, weight: .bold)
                
                Text("reading_completion.subtitle")
                    .systemFont(.body)
                    .foregroundColor(.secondary)
            } else {
                Text("reading_completion.track_your_progress")
                    .systemFont(.body)
                    .foregroundColor(colorTheme.getColor(.secondaryText))
                    .padding(.horizontal)
                
                Button(action: {
                    Task {
                        await markAsCompleted()
                    }
                }, label: {
                    Text("reading_completion.mark_as_completed")
                        .systemFont(.body, weight: .semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(colorTheme.getColor(.accent))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                })
                .padding(.top, 8)

                if hasUncompletedAzkar {
                    goToUncompletedButton
                }
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
    
    private var goToUncompletedButton: some View {
        Button(action: goToFirstUncompleted) {
            Text("reading_completion.go_to_uncompleted")
                .systemFont(.body, weight: .semibold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(colorTheme.getColor(.contentBackground))
                .foregroundColor(colorTheme.getColor(.accent))
                .cornerRadius(12)
                .padding(.horizontal)
        }
    }
}

struct ReadingCompletionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ReadingCompletionView(isCompleted: false, hasUncompletedAzkar: true, markAsCompleted: {}, goToFirstUncompleted: {})
                .previewDisplayName("Not Completed")
            ReadingCompletionView(isCompleted: true, hasUncompletedAzkar: false, markAsCompleted: {}, goToFirstUncompleted: {})
                .previewDisplayName("Completed")
        }
        .previewLayout(.sizeThatFits)
    }
}
