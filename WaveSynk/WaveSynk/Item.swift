//
//  Item.swift
//  WaveSynk
//
//  Created by Carson Cruz on 1/16/25.
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
