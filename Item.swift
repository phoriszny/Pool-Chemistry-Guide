//
//  Item.swift
//  Pool Chemistry Tracker
//
//  Created by Patrick on 7/25/24.
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
