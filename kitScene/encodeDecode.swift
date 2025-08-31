//
//  encodeDecode.swift
//  kitScene
//
//  Created by Matthew Wang on 2024-02-20.
//

import Foundation



func encodeMessage(message: Encodable) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    var sendMessage: Data?
    do {sendMessage = try encoder.encode(message)}
    catch {print("error could not encode")}
    guard let sendMessage = sendMessage else {return ""}
    print("str")
    print(String(decoding: sendMessage, as: UTF8.self))
    return String(decoding: sendMessage, as: UTF8.self)
}

func decodeMessage(message: String) -> Encodable{
    let decoder = JSONDecoder()
    var decodedMessage: Any?
    print("message")
    print(message)
    do {
        if let messageData = message.data(using: .utf8) {
            if let decoded = try? decoder.decode(Dictionary<String, Float>.self, from: messageData) {
                decodedMessage = decoded
            }
            else if let decoded = try? decoder.decode(Dictionary<String,String>.self , from: messageData){
                decodedMessage = decoded
            }
            else if let decoded = try? decoder.decode(String.self, from: messageData) {
                print(decoded)
                decodedMessage = decoded
            }
            else {
                print("error could not encode/decode")
                return Dictionary<String, Float>()
            }
        }
    }
    if let decodedMessage = decodedMessage {
        print("decoded")
        print(decodedMessage)
        return decodedMessage as! Encodable
    }
    print("error")
    return Dictionary<String, Float>()
}

