import SwiftUI

struct BriefingView: View {
    let stageName: String
    let onLaunch: () -> Void
    let onReset: () -> Void

    var body: some View {
        Group {
            Section("Briefing") {
                Text(stageName)
                    .font(.headline)
                Text("Push through a single authored attack lane, cash out credits from destroyed targets, and spend them in the between-sortie hangar.")
                Button("Launch Sortie", action: onLaunch)
                Button("Reset Loadout", role: .destructive, action: onReset)
            }
        }
    }
}
