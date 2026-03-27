import SwiftUI

struct GameplayPanel: UIViewRepresentable {
    let renderer: MetalRenderer?

    func makeUIView(context: Context) -> MetalViewportView {
        let view = MetalViewportView()
        view.renderer = renderer
        return view
    }

    func updateUIView(_ uiView: MetalViewportView, context: Context) {
        uiView.renderer = renderer
    }
}
