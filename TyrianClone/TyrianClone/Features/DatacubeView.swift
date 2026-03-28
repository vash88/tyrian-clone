import SwiftUI

struct DatacubeView: View {
    let datacube: DatacubeDefinition
    let onContinue: () -> Void

    var body: some View {
        Group {
            Section("Datacube") {
                Text(datacube.title)
                    .font(.headline)
                Text(datacube.textRef)
                Button("Continue", action: onContinue)
            }
        }
    }
}
