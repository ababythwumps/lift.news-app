//
//  Item.swift
//  lift.news
//
//  Created by Michael Kao on 9/27/25.
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
