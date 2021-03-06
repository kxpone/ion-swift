//
//  IONProtocol.swift
//  ion-swift
//
//  Created by Ivan Manov on 15.02.2020.
//  Copyright © 2020 kxpone. All rights reserved.
//

import Foundation
import Network

// Create a class that implements a framing protocol.
class IONProtocol: NWProtocolFramerImplementation {
    // Create a global definition of your ion protocol to add to connections.
    static let definition = NWProtocolFramer.Definition(implementation: IONProtocol.self)

    // Set a name for your protocol for use in debugging.
    static var label: String { return "ION" }

    // Set the default behavior for most framing protocol functions.
    required init(framer _: NWProtocolFramer.Instance) {}
    func start(framer _: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult { return .ready }
    func wakeup(framer _: NWProtocolFramer.Instance) {}
    func stop(framer _: NWProtocolFramer.Instance) -> Bool { return true }
    func cleanup(framer _: NWProtocolFramer.Instance) {}

    // Whenever the application sends a message, add your protocol header and forward the bytes.
    func handleOutput(framer: NWProtocolFramer.Instance,
                      message: NWProtocolFramer.Message,
                      messageLength: Int,
                      isComplete _: Bool) {
        // Extract the type of message.
        let type = message.ionMessageType

        // Create a header using the type and length.
        let header = IONProtocolHeader(type: type.rawValue, length: UInt32(messageLength))

        // Write the header.
        framer.writeOutput(data: header.encodedData)

        // Ask the connection to insert the content of the application message after your header.
        do {
            try framer.writeOutputNoCopy(length: messageLength)
        } catch {
            print("Hit error writing \(error)")
        }
    }

    // Whenever new bytes are available to read, try to parse out your message format.
    func handleInput(framer: NWProtocolFramer.Instance) -> Int {
        while true {
            // Try to read out a single header.
            var tempHeader: IONProtocolHeader?
            let headerSize = IONProtocolHeader.encodedSize
            let parsed = framer.parseInput(minimumIncompleteLength: headerSize,
                                           maximumLength: headerSize) { (buffer, _) -> Int in
                guard let buffer = buffer else {
                    return 0
                }
                if buffer.count < headerSize {
                    return 0
                }
                tempHeader = IONProtocolHeader(buffer)
                return headerSize
            }

            // If you can't parse out a complete header, stop parsing and ask for headerSize more bytes.
            guard parsed, let header = tempHeader else {
                return headerSize
            }

            // Create an object to deliver the message.
            var messageType = IONMessageType.invalid
            if let parsedMessageType = IONMessageType(rawValue: header.type) {
                messageType = parsedMessageType
            }
            let message = NWProtocolFramer.Message(ionMessageType: messageType)

            // Deliver the body of the message, along with the message object.
            if !framer.deliverInputNoCopy(length: Int(header.length),
                                          message: message,
                                          isComplete: true) {
                return 0
            }
        }
    }
}

// Extend framer messages to handle storing protocol message types in the message metadata.
extension NWProtocolFramer.Message {
    convenience init(ionMessageType: IONMessageType) {
        self.init(definition: IONProtocol.definition)

        self.ionMessageType = ionMessageType
    }

    var ionMessageType: IONMessageType {
        get {
            if let type = self["IONMessageType"] as? IONMessageType {
                return type
            } else {
                return .invalid
            }
        }
        set {
            self["IONMessageType"] = newValue
        }
    }
}

// Define a protocol header struct to help encode and decode bytes.
struct IONProtocolHeader: Codable {
    let type: UInt32
    let length: UInt32

    init(type: UInt32, length: UInt32) {
        self.type = type
        self.length = length
    }

    init(_ buffer: UnsafeMutableRawBufferPointer) {
        var tempType: UInt32 = 0
        var tempLength: UInt32 = 0
        withUnsafeMutableBytes(of: &tempType) { typePtr in
            typePtr.copyMemory(from: UnsafeRawBufferPointer(
                start: buffer.baseAddress!.advanced(by: 0),
                count: MemoryLayout<UInt32>.size
            ))
        }
        withUnsafeMutableBytes(of: &tempLength) { lengthPtr in
            lengthPtr.copyMemory(
                from: UnsafeRawBufferPointer(
                    start: buffer.baseAddress!.advanced(by: MemoryLayout<UInt32>.size),
                    count: MemoryLayout<UInt32>.size
                )
            )
        }
        self.type = tempType
        self.length = tempLength
    }

    var encodedData: Data {
        var tempType = self.type
        var tempLength = self.length
        var data = Data(bytes: &tempType, count: MemoryLayout<UInt32>.size)

        data.append(Data(bytes: &tempLength, count: MemoryLayout<UInt32>.size))

        return data
    }

    static var encodedSize: Int {
        return MemoryLayout<UInt32>.size * 2
    }
}
