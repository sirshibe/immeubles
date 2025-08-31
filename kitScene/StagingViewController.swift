//
//  StagingViewController.swift
//  kitScene
//
//  Created by Matthew Wang on 2024-02-20.
//
//  If multiple people join, maybe mixed messages
//  Host needs to repond to messages
//  may receive mssages that were sent before join
import UIKit
import AWSMobileClientXCF
import AWSAuthCore
import AWSSQS
import SocketIO

class StagingViewController: UIViewController {
    @IBOutlet var setupStack: UIStackView!
    @IBOutlet var playerCountControl: UISegmentedControl!
    @IBOutlet var startButton: UIButton!
    @IBOutlet var playerCounter: UILabel!
    @IBOutlet var leaveButton: UIButton!
    var isHost = false
    var settingUp = false
    var lobbyMax = 1
    var lobbyCurrent = 0
    var myPlayer: Int?
    var messageIds: Set<String> = []
    let deviceId = UIDevice.current.identifierForVendor!.uuidString
    let manager = SocketManager(socketURL: URL(string: "ws://ax.ngrok.app")!, config: [.log(true),.compress])
    override func viewDidLoad() {
        super.viewDidLoad()
        playerCounter.isHidden = true
        setupStack.isHidden = true
        startButton.isHidden = true
        startButton.tintColor = UIColor(red: 0, green: 175/255, blue: 88/255, alpha: 1)
        leaveButton.tintColor = UIColor.red
        playerCounter.text = "-/\(lobbyMax) players"
        let socket = manager.defaultSocket
        print("Connect!")
        socket.connect()
        socket.on(clientEvent: .connect) { [self]data, ack in
            print("socket connected")
            if isHost == false {
                broadcast(["deviceId":deviceId, "message" :"joinGame"])
            }
        }
        socket.on("my response") {data, ack in
            print("data!")
            print(data)
            if let strings = data as? Array<String> {
                self.handleMessages(strings)
            }
            print(data[0])
        }
        if isHost == true {
            lobbyCurrent += 1
            playerCounter.isHidden = true
            startButton.isHidden = true
            setupStack.isHidden = false
            settingUp = true
            myPlayer = 0 
        }
        else {
            setupStack.isHidden = true
            playerCounter.isHidden = false
        }
        // Do any additional setup after loading the view.
    }
    @IBAction func confirmPressed(_ sender: Any) {
        lobbyMax = playerCountControl.selectedSegmentIndex + 2
        playerCounter.text = "\(lobbyCurrent)/\(lobbyMax) players"
        startButton.isHidden = false
        playerCounter.isHidden = false
        setupStack.isHidden = true
        settingUp = false
    }
    @IBAction func startPressed(_ sender: Any) {
        if lobbyCurrent >= 2 {
            broadcast(["deviceId":deviceId, "message":"gameStart", "playerCount":String(lobbyCurrent)])
            performSegue(withIdentifier: "startGameView", sender: nil)
        }
    }
    @IBAction func leavePressed(_ sender: Any) {
        if isHost == true {
            broadcast(["deviceId":deviceId, "message":"hostLeaveGame"])
        }
        else {
            broadcast(["deviceId":deviceId, "message":"leaveGame", "playerId":String(myPlayer!)])
        }
        performSegue(withIdentifier: "leaveLobby", sender: nil)
    }
    
    func handleMessages(_ messages: Array<String>){
        for rawMessage in messages {
            let decodedMessage = decodeMessage(message: rawMessage)
            //if isHost == true {
            if let data = decodedMessage as? Dictionary<String, Any> {
                if data["deviceId"] as! String == deviceId {continue}
                if let data = data as? Dictionary<String, String> {
                    if let message = data["message"] {
                        switch message {
                        case "joinGame":
                            lobbyCurrent += 1
                            if isHost == true {
                                if lobbyCurrent > lobbyMax {
                                    broadcast(["deviceId":deviceId, "message":"lobbyFull"])
                                    lobbyCurrent -= 1
                                }
                                else {
                                    broadcast(["deviceId":deviceId, "playerId":String(lobbyCurrent-1), "playerCount":String(lobbyCurrent), "playerMax":String(lobbyMax)])
                                }
                            }
                            playerCounter.text = "\(lobbyCurrent)/\(lobbyMax) players"
                        case "gameStatus":
                            if isHost == true {
                                if settingUp == true {
                                    broadcast(["deviceId":deviceId, "message":"settingUp"])
                                }
                                else {
                                    broadcast(["deviceId":deviceId, "playerCount":String(lobbyCurrent), "playerMax":String(lobbyMax)])
                                }
                            }
                        case "leaveGame":
                            lobbyCurrent -= 1
                            if let myPlayerId = myPlayer {
                                if myPlayerId > Int(data["playerId"]!)! {
                                    myPlayer! -= 1
                                }
                                else {
                                    print("error")
                                    // if the message did not include a player id
                                    // message still contains a device id
                                }
                            }
                            else {
                                print("error")
                                // if myPlayer has not been set yet
                                // host could get dict of playerIds to deviceIds and vice versa
                                //broadcast(["deviceId":deviceId, "message":""])
                            }
                            playerCounter.text = "\(lobbyCurrent)/\(lobbyMax) players"
                        case "hostLeaveGame":
                            lobbyCurrent -= 1
                            if myPlayer != nil{
                                myPlayer! -= 1
                            }
                            else {
                                print("error")
                            }
                            if myPlayer == 0 {
                                isHost = true
                                playerCounter.isHidden = true
                                startButton.isHidden = true
                                setupStack.isHidden = false
                                settingUp = true
                                // edit start hosting with lobby setting panel
                            }
                            playerCounter.text = "\(lobbyCurrent)/\(lobbyMax) players"
                        case "gameStart":
                            lobbyCurrent = Int(data["playerCount"]!)!
                            performSegue(withIdentifier: "startGameView", sender: nil)
                        default:
                            print("I had to add this in case")
                        }
                    }
                    else if isHost == false && myPlayer == nil {
                        guard let id = data["playerId"] else {continue}
                        myPlayer = Int(id)!
                        lobbyCurrent = Int(data["playerCount"]!)!
                        lobbyMax = Int(data["playerMax"]!)!
                        playerCounter.text = "\(lobbyCurrent)/\(lobbyMax) players"
                    }
                }
            }
               /* if let message = decodedMessage as? String {
                    if message == "joinGame" {
                        lobbyCurrent += 1
                        SQS().sendMessageFifo(msg: encodeMessage(message: ["playerID":Float(lobbyCurrent - 1)]), queueURL: myQueueURL, messageDeduplicationID: String(MessageGroupId), deviceID: UIDevice.current.identifierForVendor!.uuidString)
                        MessageGroupId += 1
                    }
                    else if message == "gameStatus" {
                        if settingUp == true {
                            SQS().sendMessageFifo(msg: encodeMessage(message: "settingUp"), queueURL: myQueueURL, messageDeduplicationID: String(MessageGroupId), deviceID: UIDevice.current.identifierForVendor!.uuidString)
                        }
                        else {
                            SQS().sendMessageFifo(msg: encodeMessage(message: ["playerCount": Float(lobbyCurrent), "playerMax":Float(lobbyMax)]), queueURL: myQueueURL, messageDeduplicationID: String(MessageGroupId), deviceID: UIDevice.current.identifierForVendor!.uuidString)
                        }
                        MessageGroupId += 1
                    }
                    else if message == "leaveGame" {
                        lobbyCurrent -= 1
                    }
                }
                if let message = decodedMessage as? Dictionary<String, Float> {
                    guard myPlayer == nil else {return}
                    myPlayer = Int(message["playerID"]!)
                    lobbyCurrent = myPlayer! + 1
                }
                else if let message = decodedMessage as? String {
                    if message == "gameStart" {
                        performSegue(withIdentifier: "startGame", sender: nil)
                    }
                    else if message == "hostLeaveGame"{
                        guard myPlayer == nil else {
                            SQS().sendMessageFifo(msg: encodeMessage(message: "leaveGame"), queueURL: myQueueURL, messageDeduplicationID: String(MessageGroupId), deviceID: UIDevice.current.identifierForVendor!.uuidString)
                            MessageGroupId += 1
                            performSegue(withIdentifier: "leaveLobby", sender: nil)
                            return
                        }
                        myPlayer! -= 1
                        if myPlayer == 0 {
                            isHost = true
                            hostGame()
                        }
                    }
                    else if message == "joinGame" {
                        lobbyCurrent += 1
                    }
                    else if message == "leaveGame" {
                        lobbyCurrent -= 1
                        guard myPlayer != nil else {return}
                        myPlayer! -= 1
                    }
                }*/
        }
    }
    
    /*func receiveMessage() {
        Task {
            var ret: [String] = []
            let sqs = AWSSQS.default()
            
            // Initialize SQS send message request
            let queryMsgRequest = AWSSQSReceiveMessageRequest()
            
            // Queue URL (not the queue ARN)
            queryMsgRequest?.queueUrl = myQueueURL
            //print("Polling for messages...")
            
            guard let queryMsgRequest = queryMsgRequest else {return}
        let result = try await sqs.receiveMessage(queryMsgRequest)
        //print(result)
            //print(result.messages?.first?.body)
        print("result.messages")
        print(result.messages)
        for message in result.messages ?? [] {
            print("message id:\(message.messageId!)")
            //print("Message Id:", message.messageId ?? "[no id]")
            //print("Content:", message.body ?? "[no message]")
            if let body = message.body {
                print(messageIds)
                print(message.messageId)
                print(!(messageIds.contains(message.messageId!)))
                guard !(messageIds.contains(message.messageId!)) else {continue}
                ret.append(message.body ?? " [no message] ")
                print("body-sdf")
                print(body)
            }
            messageIds.insert(message.messageId!)
                 if let handle = message.receiptHandle {
                    /*var delRequest = AWSSQSDeleteMessageRequest()
                    delRequest?.queueUrl = myQueueURL
                    delRequest?.receiptHandle = handle
                    // deleteRequest = sqs.DeleteMessageRequest(queueUrl: self.queueUrl, receiptHandle: handle)
                    guard let delRequest = delRequest else {print("failed to generate delete request");return}
                    //_ = try await sqs.deleteMessage(delRequest)*/
                }
            }
            print("message")
            print(ret)
            // call function
            if ret.count > 0 {
                print("ytes")
                handleMessages(ret)
            }
        }
    }*/
    
    func hostGame() {
        playerCounter.isHidden = true
        startButton.isHidden = true
        setupStack.isHidden = false
        settingUp = true
        DispatchQueue.global(qos: .userInitiated).async {
            print("start hosting")
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                print("recive message")
                //self.receiveMessage()
            }
            RunLoop.current.run()
        }
    }
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        manager.disconnect()
        if let vc = segue.destination as? GameViewController {
            vc.numPlayers = lobbyCurrent
            vc.yourPlayer = myPlayer!
            vc.isMultiplayer = true
        }
    }
    
    func broadcast(_ data: Encodable) {
        let message = encodeMessage(message: data)
        let socket = manager.defaultSocket
        socket.emit("broadcast", message)
        print("sent message: \(message)")
    }
    
}
