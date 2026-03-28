import Foundation

enum AppScreen {
    case intermission
    case stage
    case shop
    case datacube
    case branch
    case episodeTransition
    case destroyed

    var displayTitle: String {
        switch self {
        case .intermission:
            "Intermission"
        case .stage:
            "Mission"
        case .shop:
            "Shop"
        case .datacube:
            "Datacube"
        case .branch:
            "Route"
        case .episodeTransition:
            "Transition"
        case .destroyed:
            "Destroyed"
        }
    }
}
