//  -------------------------------------------------------------------
//  File: NIO_TCP_Client.swift
//
//  This file is part of the SatController 'Suite'. It's purpose is
//  to remotely control and monitor a QO-100 DATV station over a LAN.
//
//  Copyright (C) 2021 Michael Naylor EA7KIR http://michaelnaylor.es
//
//  The 'Suite' is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  The 'Suite' is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General License for more details.
//
//  You should have received a copy of the GNU General License
//  along with  SatServer.  If not, see <https://www.gnu.org/licenses/>.
//  -------------------------------------------------------------------

// Adapted from Cory's Client Example
// https://forums.swift.org/t/which-nio-example-to-adapt/56768/2

import Foundation
import NIOCore
import NIOPosix
import NIOFoundationCompat

final class NIO_TCP_Client {
    typealias DataCallback = (Data) -> Void
    
    private final class ClientHandler: ChannelInboundHandler {
        typealias InboundIn = ByteBuffer
        
//        fileprivate var dataCallback: DataCallback
        
//        init(dataCallback: @escaping DataCallback) {
//            self.dataCallback = dataCallback
//        }
        
        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            let buffer = self.unwrapInboundIn(data)
//            self.dataCallback(Data(buffer: buffer))
        }
    }
    
    private let channel: Channel
    
    private init(channel: Channel) {
        self.channel = channel
    }
    
    static func connect(host: String, port: Int) throws -> NIO_TCP_Client {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1) //System.coreCount)
        let bootstrap = ClientBootstrap(group: group)
            .channelInitializer { channel in
                return channel.pipeline.addHandler(ClientHandler())
            }
        
        let channel = try bootstrap.connect(host: host, port: port).wait()
        
        return NIO_TCP_Client(channel: channel)
    }
    
    var isConnected: Bool {
        return self.channel.isActive
    }
    
    func send(_ data: Data) {
        self.channel.writeAndFlush(ByteBuffer(data: data), promise: nil)
    }
    
    func disconnect() {
        self.channel.close(promise: nil)
    }
}

