import SwiftUI

@main
struct TyrianCloneApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            MainScreen(appModel: appModel)
                .preferredColorScheme(.dark)
        }
    }
}
