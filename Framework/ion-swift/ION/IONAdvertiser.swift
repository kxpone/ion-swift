//
//  IONAdvertiser.swift
//  ion-swift
//
//  Created by Ivan Manov on 05.01.2020.
//  Copyright © 2020 kxpone. All rights reserved.
//

import Foundation
import Network

class IONAdvertiser: Advertiser {
    var isAdvertising: Bool = false
    weak var advertiserDelegate: AdvertiserDelegate?

    let type: String
    var listener: NWListener?
    let dispatchQueue: DispatchQueue
    var connections: [IONUnderlyingConnection] = []

    init(type prefix: String, dispatchQueue: DispatchQueue) {
        self.type = "_\(prefix)._tcp"
        self.dispatchQueue = dispatchQueue

        self.prepareListener()
    }

    private func prepareListener() {
        // Create the listener object.
        guard let listener = try? NWListener(using: IONLocalPeer.dafaultParemeters) else {
            print("Failed to create listener")
            return
        }

        self.listener = listener
        self.handleUpdates()
    }

    private func handleUpdates() {
        guard let listener = self.listener else { return }

        listener.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                print("Listener ready on \(String(describing: listener.port))")
                self.isAdvertising = true
            case let .failed(error):
                print("Listener failed with \(error), restarting...")
                self.isAdvertising = false
                self.restartAdvertising()
            default:
                self.isAdvertising = false
            }
        }

        listener.newConnectionHandler = { newConnection in
            if let delegate = self.advertiserDelegate {
                let connection = IONUnderlyingConnection(with: newConnection, dispatchQueue: self.dispatchQueue)
                connection.connect()
                connection.connectionHandler = { connected, _ in
                    if connected {
                        delegate.handleConnection(self, connection: connection)
                    } else {
                        connection.connect()
                    }
                }

//                if let existingConnection = self.connections.first(where: { $0.connection?. == newConnection.endpoint }) {
//                    if existingConnection.isConnected {
//                        existingConnection.connect()
//                    }
//                } else {
//                    self.connections.append(connection)
//                    connection.connect()
//                }
//                connection.connectionHandler = { succeed, _ in
//                    if succeed {
//                    }
//                }
            } else {
                log(.high, error: "Received incoming connection, but there's no delegate set.")
            }
        }
    }

    func restartAdvertising() {
        guard let listener = self.listener else { return }
        self.connections.removeAll()

        listener.cancel()
        self.advertiserDelegate?.didStopAdvertising(self)

        listener.start(queue: self.dispatchQueue)

        self.dispatchQueue.async {
            self.advertiserDelegate?.didStartAdvertising(self)
        }
    }

    // MARK: Advertiser protocol methods

    func startAdvertising(_ identifier: UUID) {
        guard let listener = self.listener else { return }

        // Set the service to advertise.
        listener.service = NWListener.Service(name: identifier.UUIDString, type: self.type)

        // Start listening, and request updates on the dispatchQueue.
        listener.start(queue: self.dispatchQueue)
        self.dispatchQueue.async {
            self.advertiserDelegate?.didStartAdvertising(self)
        }
    }

    func stopAdvertising() {
        guard let listener = self.listener else { return }
        self.connections.removeAll()

        listener.cancel()
        self.dispatchQueue.async {
            self.advertiserDelegate?.didStopAdvertising(self)
        }
    }
}
