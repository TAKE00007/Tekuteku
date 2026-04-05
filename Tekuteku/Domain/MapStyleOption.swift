import SwiftUI
import MapKit

enum MapStyleOption: Equatable {
    case standard
    case hybrid
    
    var name: String {
        switch self {
        case .standard:
            return "スタンダード"
        case .hybrid:
            return "航空写真"
        }
    }
    var mapStyle: MapStyle {
        switch self {
        case .standard:
            return .standard(elevation: .realistic)
        case .hybrid:
            return .hybrid(elevation: .realistic)
        }
    }
}
