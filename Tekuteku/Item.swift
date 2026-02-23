//
//  Item.swift
//  Tekuteku
//
//  Created by 大竹駿 on 2026/02/23.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
