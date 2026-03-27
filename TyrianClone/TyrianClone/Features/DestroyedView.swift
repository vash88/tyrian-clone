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
                Text("You lost the run with \(earned) credits banked this sortie. This parity build resets the campaign on destruction so the loop stays sharp and readable.")
                Button("Restart Campaign", action: onRestartCampaign)
                Button("Back To Briefing", action: onBriefing)
            }
        }
    }
}
