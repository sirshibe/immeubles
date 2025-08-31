//
//  GameFinderViewController.swift
//  kitScene
//
//  Created by Matthew Wang on 2024-02-19.
//

import UIKit
import SocketIO
//import AWSCore
//import AWSMobileClientXCF
//import AWSAuthCore
//import AWSSQS
//import AWSSNS
//import AWSLocationXCF

class FinderViewController: UIViewController {
    @IBOutlet var playerCount: UILabel!
    @IBOutlet var joinGame: UIButton!
    @IBOutlet var loadingView: UIActivityIndicatorView!
    var count = 0
    //var idtask = AWSMobileClient.default().getIdentityId()
    var joinIsEnabled = false
    var willHost: Bool?
    let manager = SocketManager(socketURL: URL(string: "ws://ax.ngrok.app")!, config: [.log(true),.compress])
    override func viewDidLoad() {
        super.viewDidLoad()
        let socket = manager.defaultSocket
        print("Connect!")
        socket.connect()
        socket.on(clientEvent: .connect) { [self]data, ack in
            print("socket connected")
            print(manager.defaultSocket.status)
            broadcast(["deviceId":UIDevice.current.identifierForVendor!.uuidString,
                               "message":"gameStatus"])
        }
        socket.on("my response") {data, ack in
            print(data)
            print(type(of: data[0]))
            print(ack)
            if let strings = data as? Array<String> {
                print(strings)
                self.handleMessages(strings)
            }
            print(data[0])
            //self.label.text=data[0] as! String
        }
        /*AWSDDLog.sharedInstance.logLevel = .off
        logout()
        login()
        print(AWSMobileClient.default().currentUserState)*/
        //requestRoom()
        playerCount.text = "- players"
        joinGame.tintColor = UIColor.red
        joinGame.titleLabel?.textColor = UIColor.white
        joinIsEnabled = false
        loadingView.startAnimating()
        loadingView.isHidden = false
        let timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.update), userInfo: nil, repeats: false)
        // Do any additional setup after loading the view.
    }
    
    @objc func update() {
        playerCount.text = "0 players"
        joinGame.tintColor = UIColor(red: 0, green: 175/255, blue: 88/255, alpha: 1)
        joinIsEnabled = true
        loadingView.stopAnimating()
        loadingView.isHidden = true
        willHost = true
    }
    
    @IBAction func joinRoom(_ sender: Any) {
        if joinIsEnabled == true {
            performSegue(withIdentifier: "joinGame", sender: nil)
        }
    }
    
    func handleMessages(_ messages: Array<String>) {
        print("messages!")
        print(messages)
        // find correct message instead of first
        for rawMessage in messages {
            let decodedMessage = decodeMessage(message: rawMessage)
            if let message = decodedMessage as? Dictionary<String, Any> {
                if message["deviceId"] as! String == UIDevice.current.identifierForVendor!.uuidString {continue}
                if let string = message["messsage"] as? String {
                    if string == "settingUp" {
                        joinGame.tintColor = UIColor.red
                        joinIsEnabled = false
                        joinGame.titleLabel?.textColor = UIColor.white
                        playerCount.text = "Host is setting up the game..."
                    }
                }
                else if let countPlayer = message["playerCount"] as? String {
                    let playerMax = message["playerMax"] as! String
                    playerCount.text = "\(countPlayer)/\(playerMax) players"
                    loadingView.stopAnimating()
                    loadingView.isHidden = true
                    willHost = false
                    if (Int(playerMax)! - Int(countPlayer)!) >= 1{
                        joinGame.tintColor = UIColor(red: 0, green: 175/255, blue: 88/255, alpha: 1)
                        joinIsEnabled = true
                    }
                    else {
                        joinGame.tintColor = UIColor.red
                        joinIsEnabled = false
                        joinGame.titleLabel?.textColor = UIColor.white
                    }
                }
            }
            //else if let message = decodedMessage as? String {
                /*if message == "settingUp" {
                    joinGame.tintColor = UIColor.red
                    joinIsEnabled = false
                    joinGame.titleLabel?.textColor = UIColor.white
                    playerCount.text = "Host is setting up the game..."
                }*/
            //}
        }
    }
    
    /*func requestRoom() {
        var numPeople: Int?
        var gameStarted: Bool?
        playerCount.text = "- players"
        joinGame.tintColor = UIColor.red
        joinGame.titleLabel?.textColor = UIColor.white
        joinIsEnabled = false
        loadingView.startAnimating()
        loadingView.isHidden = false
        count = 0
        DispatchQueue.global(qos: .userInitiated).async {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] timer in
                if timerInvalidate {timer.invalidate()}
                print("Timer fired!")
                count += 1
                if AWSMobileClient.default().isSignedIn && !messageSent{
                    let msg = encodeMessage(message: "gameStatus")
                    print("send message")
                    SQS().sendMessageFifo(msg: msg, queueURL: myQueueURL, messageDeduplicationID: String(MessageGroupId), deviceID: UIDevice.current.identifierForVendor!.uuidString)
                    MessageGroupId += 1
                    messageSent = true
                }
                else if AWSMobileClient.default().isSignedIn {
                    receiveMessage()
                }
                if count == 5 {
                    DispatchQueue.main.async {
                        self.setEmpty()
                    }
                    timer.invalidate()
                }
            }
            RunLoop.current.run()
        }
    }*/
    
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
            print(result.messages?.first?.body)
        for message in result.messages ?? [] {
            
            //print("Message Id:", message.messageId ?? "[no id]")
            //print("Content:", message.body ?? "[no message]")
            if let body = message.body {
                print(body)
                guard !(message.body == encodeMessage(message: "gameStatus")) else {continue}
                guard !(messageIds.contains(message.messageId!)) else {continue}
                ret.append(message.body ?? " [no message] ")
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
    
    /*func setEmpty(){
        playerCount.text = "0 players"
        joinGame.tintColor = UIColor(red: 0, green: 175/255, blue: 88/255, alpha: 1)
        joinIsEnabled = true
        loadingView.stopAnimating()
        loadingView.isHidden = true
        willHost = true
    }*/
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        manager.disconnect() 
        let vc = segue.destination as? StagingViewController
        vc?.isHost = willHost!
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    
    func broadcast(_ data: Encodable) {
        let message = encodeMessage(message: data)
        let socket = manager.defaultSocket
        socket.emit("broadcast", message)
        print("sent message: \(message)")
    }
}
