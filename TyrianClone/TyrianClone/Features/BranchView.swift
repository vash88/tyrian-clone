import SwiftUI

struct BranchView: View {
    let options: [NavNodeDefinition]
    let onChoose: (String) -> Void

    var body: some View {
        Group {
            Section("Route Choice") {
                Text("Choose the next campaign route.")
                ForEach(options) { option in
                    Button(option.title) {
                        onChoose(option.id)
                    }
                }
            }
        }
    }
}
