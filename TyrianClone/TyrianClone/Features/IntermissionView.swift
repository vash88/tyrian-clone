import SwiftUI

struct IntermissionView: View {
    let title: String
    let bodyText: String
    let primaryActionTitle: String
    let onPrimaryAction: () -> Void
    let onReset: () -> Void

    var body: some View {
        Group {
            Section(title) {
                Text(bodyText)
                Button(primaryActionTitle, action: onPrimaryAction)
                Button("Reset Campaign", role: .destructive, action: onReset)
            }
        }
    }
}
