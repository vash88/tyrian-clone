import SwiftUI

struct DestroyedView: View {
    let outcome: StageOutcome?
    let onRestartCampaign: () -> Void
    let onBriefing: () -> Void

    var body: some View {
        let earned = outcome?.earned ?? 0
        Group {
            Section("Destroyed") {
                Text("Hull Breach")
                    .font(.headline)
                Text("You lost the mission after collecting \(earned) mission credits. Purchased equipment remains part of the campaign loadout, but mission-local gains were not carried forward.")
                Button("Restart Campaign", action: onRestartCampaign)
                Button("Return To Briefing", action: onBriefing)
            }
        }
    }
}
