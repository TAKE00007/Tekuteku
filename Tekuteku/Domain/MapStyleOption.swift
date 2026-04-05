import SwiftUI
import MapKit

enum MapStyleOption: Equatable {
    case standard
    case hybrid
    
    var mapStyle: MapStyle {
        switch self {
        case .standard:
            return .standard(elevation: .realistic)
        case .hybrid:
            return .hybrid(elevation: .realistic)
        }
    }
}
