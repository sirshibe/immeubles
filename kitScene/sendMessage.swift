//
//  sendMesage.swift
//  kitScene
//
//  Created by Matthew Wang on 2024-03-15.
//

import Foundation
import SocketIO

public class ngrok {
    static let manager = SocketManager(socketURL: URL(string: "https://ax.ngrok.app")!, config: [.log(true),.compress])
    public func broadcast(_ data: Encodable) {
        let message = encodeMessage(message: data)
        let socket = ngrok.manager.defaultSocket
        socket.emit("broadcast", message)
        print("sent message: \(message)")
    }
}
