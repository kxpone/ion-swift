//
//  ConnectionInfo.swift
//  ion-swift
//
//  Created by Ivan Manov on 15.02.2020.
//  Copyright © 2020 kxpone. All rights reserved.
//

import Foundation

/// Connection related info
struct ConnectionInfo: Codable {
    /// Nodes identifiers
    let sourceNodeId: String
    let destinationNodeId: String

    /// Range: 0..1. More is better.
    /// Calculated based on (Received / Transmitted) num of data during the connection probe
    var lossRatio: Float?
    /// Range: 0..Inf. In milliseconds. Less is better.
    /// Calculated based on average delay of packet transmission during the connection probe
    var delay: Float?
    /// Range: 0..Inf. In megabits. More is better.
    /// Calculates based on max allocated bandwidth during the last connection probe
    var bandwidth: Float?
}