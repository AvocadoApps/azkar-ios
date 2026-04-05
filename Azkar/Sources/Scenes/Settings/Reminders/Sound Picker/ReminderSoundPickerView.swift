import SwiftUI
import Library

struct ReminderSoundPickerView: View {
    
    @ObservedObject var viewModel: ReminderSoundPickerViewModel
    @Environment(\.appTheme) var appTheme
    
    var body: some View {
        ScrollView {
            ForEach(viewModel.sections) { section in
                VStack(spacing: 0) {
                    HeaderView(text: LocalizedStringKey(section.title))
                    
                    VStack {
                        ForEachIndexed(section.sounds) { _, position, sound in
                            soundView(sound)
                            if position != .last {
                                Divider()
                            }
                        }
                    }
                    .applyContainerStyle()
                }
            }
        }
        .environment(\.horizontalSizeClass, .regular)
        .customScrollContentBackground()
        .background(.background, ignoreSafeArea: .all)
        .navigationTitle("settings.reminders.sounds.sound")
        .onAppear {
            AnalyticsReporter.reportScreen("Settings", className: viewName)
        }
    }
    
    private func soundView(_ sound: ReminderSound) -> some View {
        let isSelected = viewModel.preferredSound == sound
        let hasAccess = viewModel.hasAccessToSound(sound)

        return Button {
            DispatchQueue.main.async {
                viewModel.playSound(sound)
                viewModel.setPreferredSound(sound)
            }
        } label: {
            HStack(alignment: .center, spacing: 8) {
                Text(sound.title)
                    .multilineTextAlignment(.leading)
                    .systemFont(.body)

                Spacer()

                if hasAccess || isSelected {
                    CheckboxView(isCheked: .constant(isSelected))
                        .frame(width: 20, height: 20)
                } else {
                    ProBadgeView()
                }
            }
            .contentShape(Rectangle())
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.text)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(sound.title)
        .accessibilityValue(soundAccessibilityValue(isSelected: isSelected, hasAccess: hasAccess))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func soundAccessibilityValue(isSelected: Bool, hasAccess: Bool) -> Text {
        if !hasAccess && !isSelected {
            return Text("accessibility.item-picker.locked")
        }

        return isSelected ? Text("accessibility.common.selected") : Text("accessibility.common.not-selected")
    }
    
}

#Preview("Reminder Sound Picker") {
    ReminderSoundPickerView(viewModel: .placeholder)
}
