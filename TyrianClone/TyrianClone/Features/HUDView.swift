import SwiftUI

struct HUDView: View {
    let screen: AppScreen
    let runState: RunState
    let snapshot: HUDSnapshot

    var body: some View {
        Group {
            Section("Flight Systems") {
                systemProgressRow(title: "Armor", value: snapshot.armor, total: snapshot.maxArmor)
                systemProgressRow(title: "Shield", value: snapshot.shield, total: snapshot.maxShield)
                systemProgressRow(title: "Energy", value: snapshot.energy, total: snapshot.maxEnergy)

                LabeledContent("Rear Mode", value: snapshot.rearModeLabel)
                LabeledContent("Front Weapon", value: "\(snapshot.frontName) P\(snapshot.frontPower)")
                LabeledContent("Rear Weapon", value: "\(snapshot.rearName) P\(snapshot.rearPower)")
                LabeledContent("Left Sidekick", value: snapshot.leftSidekickName)
                LabeledContent("Right Sidekick", value: snapshot.rightSidekickName)
            }

            Section("Mission Status") {
                missionProgressRow
                LabeledContent("Phase", value: screen.rawValue.uppercased())
                LabeledContent("Sortie", value: "\(runState.sortie)")
                LabeledContent("Credits", value: "\(runState.credits)")
                LabeledContent("Stage Time", value: String(format: "%.1fs", snapshot.stageTime))
            }
        }
    }

    private var missionProgressRow: some View {
        let progress = snapshot.stageDuration > 0 ? min(snapshot.stageTime / snapshot.stageDuration, 1) : 0
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Stage Progress")
                Spacer()
                Text("\(Int(progress * 100))%")
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: progress)
        }
    }

    private func systemProgressRow(title: String, value: Double, total: Double) -> some View {
        let safeTotal = max(total, 1)
        let progress = min(max(value / safeTotal, 0), 1)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(ceil(value))) / \(Int(total))")
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: progress)
        }
    }
}
