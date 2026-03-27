import SwiftUI

struct MainScreen: View {
    @ObservedObject var appModel: AppModel
    @State private var isPanelPresented = true
    @State private var previewRenderer = MetalRenderer()
    @StateObject private var fpsCounter = FPSCounter()
    private let compactDetent = PresentationDetent.height(200)

    var body: some View {
        gameplayArea
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        .onAppear(perform: syncPreviewRenderer)
        .onChange(of: appModel.runState) { _, _ in
            syncPreviewRenderer()
        }
        .onChange(of: appModel.screen) { _, _ in
            syncPreviewRenderer()
        }
        .sheet(isPresented: $isPanelPresented) {
            NavigationStack {
                Form {
                    stateSections

                    HUDView(
                        screen: appModel.screen,
                        runState: appModel.runState,
                        snapshot: appModel.hudSnapshot
                    )
                }
            }
            .interactiveDismissDisabled()
            .presentationDetents([compactDetent, .large])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled(upThrough: compactDetent))
        }
    }

    @ViewBuilder
    private var stateSections: some View {
        switch appModel.screen {
        case .briefing:
            BriefingView(stageName: appModel.stage.name, onLaunch: appModel.launchSortie, onReset: appModel.restartCampaign)
        case .stage:
            EmptyView()
        case .shop:
            ShopView(appModel: appModel)
        case .destroyed:
            DestroyedView(
                outcome: appModel.lastOutcome,
                onRestartCampaign: appModel.restartCampaign,
                onBriefing: appModel.returnToBriefing
            )
        }
    }

    @ViewBuilder
    private var gameplayArea: some View {
        let viewport = GameplayPanel(renderer: appModel.gameplayViewModel?.renderer ?? previewRenderer)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        if appModel.screen == .stage {
            viewport
                .overlay(alignment: .topLeading) {
                    fpsBadge
                }
        } else {
            viewport
                .overlay(alignment: .top) {
                    Text(statusTitle)
                        .padding(.top, 60)
                        .padding(.horizontal, 12)
                        .background(.thinMaterial, in: Capsule())
                }
                .overlay(alignment: .topLeading) {
                    fpsBadge
                }
        }
    }

    private var fpsBadge: some View {
        Text("\(fpsCounter.fps) FPS")
            .font(.caption2.monospacedDigit())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.thinMaterial, in: Capsule())
            .padding(.top, 56)
            .padding(.leading, 12)
    }

    private var statusTitle: String {
        switch appModel.screen {
        case .briefing:
            appModel.stage.name
        case .stage:
            "Stage Active"
        case .shop:
            "Hangar"
        case .destroyed:
            "Hull Breach"
        }
    }

    private func syncPreviewRenderer() {
        guard appModel.screen != .stage else {
            return
        }
        previewRenderer.update(snapshot: .preview(from: appModel.runState))
    }
}
