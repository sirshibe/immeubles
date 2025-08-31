/*
 GameViewController.swift
 kitScene / immeubles

 Created by Matthew Wang on 2024-01-07.
 
 Bugs/Improvements:
 - allows you to move/build before calculations and animations are finished
 - auto generate ground and remove pre-generated ground so no loop through them in updateAvailableMoves()
    - after that add option for adjustable board size
 - when auto generating players, assign names
    - add it in setup screen
 - remove playercoords parameter
 - add sounds
 - after setup, last person to setup's player indicator does not work
 - what to do if no possible moves left
 - stop camera from going below water
 - extra things to be configurable:
    - add option for multiple figures for each person
    - how many layers of buildings possible
    - option for adjustable board size (already above)
 Finished
 - add fireworks to victory screen using particle system
 - you can play during other peoples turn
 - fix outdated message fifo system
 - when to delete messages
 - staging room, lobby need to be setup
 - sometimes does not highlight squares on buildings (does not highlight squares below player)
 - omni light still there during victory cutscene
*/

import UIKit
import SceneKit
import SocketIO
import SwiftUI
import RealityKit
//import AWSMobileClientXCF
//import AWSAuthCore
//import AWSSQS

class GameViewController: UIViewController {
    @IBOutlet var leaveButton: UIButton!
    @IBOutlet var menuView: UIView!
    @IBOutlet var mainView: UIView!
    @IBOutlet var menuButton: UIButton!
    enum status {
        case move, build
    }
    
    enum object {
        case building, ground, player
    }
    
    struct Player {
        var node: SCNNode
        var id: Int
        var location: SCNVector3
    }
    
    let colors = [UIColor(red: 1, green: 38/255, blue: 0, alpha: 1),
                  UIColor(red: 0, green: 38/255, blue: 1, alpha: 1),
                  UIColor(red: 0, green: 200/255, blue: 0, alpha: 1),
                  UIColor.yellow]
    let spawnLocs = [SCNVector3(-1, 0.3, 0), SCNVector3(1, 0.3, 0), SCNVector3(0, 0.3, -1), SCNVector3(0, 0.3, 1)]
    var yourPlayer = 0
    var gameStatus: status = .move
    var gameScene: SCNScene!
    var players: [Player] = []
    var cameraNode: SCNNode?
    var player: Player?
    var fireworks: SCNParticleSystem?
    var numPlayers = 2
    var setup = true
    var setupCounter = 0
    let deviceId = UIDevice.current.identifierForVendor!.uuidString
    let manager = SocketManager(socketURL: URL(string: "ws://ax.ngrok.app")!, config: [.log(true),.compress])
    //var dinga = 0
    //var MessageGroupId = 0
    //var messageIds: Set<String> = []
    // Make sure this is the QueueURL (https://), not the QueueARN and not the Queue name
    //let myQueueURL: String = "https://sqs.us-east-1.amazonaws.com/992382396102/abc.fifo"
    var buildingsBoard: [[Int]] = [[0, 0, 0, 0, 0],
                                   [0, 0, 0, 0, 0],
                                   [0, 0, 0, 0, 0],
                                   [0, 0, 0, 0, 0],
                                   [0, 0, 0, 0, 0]]
    var playersBoard: [[Int]] = [[0, 0, 0, 0, 0],
                                [0, 0, 0, 0, 0],
                                [0, 0, 0, 0, 0],
                                [0, 0, 0, 0, 0],
                                [0, 0, 0, 0, 0]]
    var menuOpened = false
    var isOnline = false
    var yourTurn = true
    var currentPlayer = 0
    var winPlayer = ""
    @IBOutlet var playerIndicator: UIImageView!
    @IBOutlet var switchModes: UIButton!
    @IBOutlet var gameView: SCNView!
    @IBOutlet var label: UILabel!
    @IBOutlet var tapRecognizer: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        menuView.layer.cornerRadius = 10
        menuView.alpha = 0
        menuView.backgroundColor = UIColor.lightGray
        leaveButton.alpha = 0
        leaveButton.imageView?.tintColor = UIColor.red
        if isOnline == true {
            let socket = manager.defaultSocket
            socket.connect()
            socket.on(clientEvent: .connect) { [self]data, ack in
                print("socket connected")
            }
            socket.on("my response") {data, ack in
                print("data!")
                print(data)
                if let strings = data as? Array<String> {
                    self.handleMessages(strings)
                }
                print(data[0])
            }
            if yourPlayer != 0 {
                yourTurn = false
            }
        }
        //AWSDDLog.sharedInstance.logLevel = .off
        setupScene()
        //if AWSMobileClient.default().currentUserState == .signedIn {logout()}
        //login()
        /*DispatchQueue.global(qos: .userInitiated).async {
            let timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
            RunLoop.current.run()
        }*/
    }

    func handleMessages(_ messages: Array<String>){
        for rawMessage in messages {
            let decodedMessage = decodeMessage(message: rawMessage)
            if let data = decodedMessage as? Dictionary<String, Any> {
                if let data = data as? Dictionary<String, Float> {
                    if Int(data["player"]!) == yourPlayer {continue}
                    guard let mode = data["mode"] else {continue}
                    switch mode {
                    case 1:
                        player = players[Int(data["player"]!)]
                        movePlayer(to: SCNVector3(x: data["x"]!, y: data["y"]!, z: data["z"]!), player: player!)
                        players[Int(data["player"]!)].location = SCNVector3(x: data["x"]!, y: data["y"]!, z: data["z"]!)
                        gameStatus = .build
                    case 2:
                        if numPlayers - Int(data["player"]!) == 1 {
                            player = players[0]
                        }
                        else {
                            player = players[Int(data["player"]!) + 1]
                        }
                        if data["y"]! < 0.25 {
                            build(name: "ground", nodeLocation: SCNVector3(x: data["x"]!, y: data["y"]!, z: data["z"]!))
                        }
                        else {
                            build(name: "building", nodeLocation: SCNVector3(x: data["x"]!, y: (data["y"]!), z: data["z"]!))
                        }
                        gameStatus = .move
                        if Int(data["player"]!) + 1 == yourPlayer || (yourPlayer == 0 && Int(data["player"]!) + 1 == players.count){
                            updateAvailableMoves(playerCoords: players[yourPlayer].location)
                            yourTurn = true
                        }
                        if Int(data["player"]!) + 1 < players.count{
                            playerIndicator.tintColor = colors[Int(data["player"]!)]
                        }
                        else {
                            playerIndicator.tintColor = colors[0]
                        }
                    case 3:
                        let playerLocation = SCNVector3(x: data["x"]!, y: data["y"]!, z: data["z"]!)
                        players.append(Player(node: addPlayer(position: playerLocation, color: colors[setupCounter]), id: setupCounter, location: playerLocation))
                        setupCounter += 1
                        if yourPlayer == setupCounter{
                            yourTurn = true
                            label.text = "Player \(setupCounter+1) (you), choose your starting position."
                            playerIndicator.tintColor = colors[setupCounter]
                        }
                        if setupCounter == numPlayers {
                            setup = false
                            label.text = "Start playing!"
                            player = players[0]
                            if yourPlayer == 0 {
                                yourTurn = true
                                updateAvailableMoves(playerCoords: players[0].location)
                            }
                        }
                    default:
                        print("unknown mode")
                        continue
                    }
                }
                if let data = data as? Dictionary<String, String> {
                    if data["message"]! == "gameWin"{
                        winPlayer = String(Int(data["player"]!)!+1)
                        saveScene()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            self.performSegue(withIdentifier: "victory", sender: nil)
                        }
                    }
                    // fix: could be an outside request
                }
            }
        }
    }
    
    @IBAction func menuOpen(_ sender: Any) {
        if menuOpened == false {
            menuOpened = true
            UIView.animate(withDuration: 1) { [self] in
                menuView.alpha = 0.5
                label.alpha = 0
                leaveButton.alpha = 1
            }
        }
        else {
            menuOpened = false
            UIView.animate(withDuration: 1) { [self] in
                menuView.alpha = 0
                label.alpha = 1
                leaveButton.alpha = 0
            }
        }
    }
    
    @objc func update(){
        //dinga += 1
        //print(dinga)
        //receiveMessage()
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
            print(result.messages?.first?.body)
        for message in result.messages ?? [] {
            messageIds.insert(message.messageId!)
            //print("Message Id:", message.messageId ?? "[no id]")
            //print("Content:", message.body ?? "[no message]")
            ret.append(message.body ?? " [no message] ")
                 if let handle = message.receiptHandle {
                    var delRequest = AWSSQSDeleteMessageRequest()
                    delRequest?.queueUrl = myQueueURL
                    delRequest?.receiptHandle = handle
                    // deleteRequest = sqs.DeleteMessageRequest(queueUrl: self.queueUrl, receiptHandle: handle)
                    guard let delRequest = delRequest else {print("failed to generate delete request");return}
                    _ = try await sqs.deleteMessage(delRequest)
                }
            }
            print("message")
            print(ret)
            // call function
            if ret.count > 0 {
                print("ytes")
                handleMessages(messages: ret)
                //decodeMessage(message: ret[0])
            }
        }
    }*/
    
    /*func handleMessages(messages: Array<String>) {
    var decodedMessages: [Dictionary<String, Float>] = []
        for message in messages {
            decodedMessages.append(decodeMessage(message: message) as! Dictionary<String, Float>)
        }
        for decodedMessage in decodedMessages {
            //executeAction(action: decodedMessage)
            print("handled message")
            print(decodedMessage)
        }
    }*/
    
    func setupScene() {
        
        gameView.allowsCameraControl = true
        gameScene = SCNScene(named: "mainScene.scn")
        gameView.scene = gameScene
        gameView.isPlaying = true
        tapRecognizer.addTarget(self, action: #selector(GameViewController.screenTapped(recognizer:)))
        gameView.addGestureRecognizer(tapRecognizer)
        /*for i in 0...numPlayers - 1 {
            players.append(Player(node: addPlayer(position: spawnLocs[i], color: colors[i]), id: i, location: spawnLocs[i]))
            playersBoard[Int(round(spawnLocs[i].z)) + 2][Int(round(spawnLocs[i].x)) + 2] = i + 1
        }
        player = players[0]
        //addPlayer(position: SCNVector3(x:-1, y:0.3, z:0), color: colors[0])
        updateAvailableMoves(playerCoords: (player?.node.worldPosition)!)*/
        switchModes.isHidden = true
        playerIndicator.tintColor = colors[0]
        if isOnline == false {
            label.text = "Player \(setupCounter+1), choose your starting position."
        }
        else if yourTurn == true {
            label.text = "Player \(setupCounter+1) (you), choose your starting position."
        }
        /* print(playersBoard[0])
        print(playersBoard[1])
        print(playersBoard[2])
        print(playersBoard[3])
        print(playersBoard[4]) */
    }
    
    func addPlayer(position: SCNVector3, color: UIColor) -> SCNNode {
        let playerNode = SCNNode(geometry: SCNCapsule(capRadius: 0.25, height: 0.75))
        gameScene.rootNode.addChildNode(playerNode)
        playerNode.position = position
        playerNode.geometry?.firstMaterial?.diffuse.contents = color
        playerNode.geometry?.firstMaterial?.lightingModel = .physicallyBased
        playerNode.name = "player"
        return playerNode
    }
    
    @IBAction func buttonPressed(_ sender: Any) {
        if gameStatus == .build {
            gameStatus = .move
        }
        else {
            gameStatus = .build
        }
    }
    
    //domes dont have name
    func addNode(position: SCNVector3, thing: String) -> SCNNode {
        var url: URL?
        if thing == "building" {
            if position.y >= 2 {
                url = Bundle.main.url(forResource: "thirdBuilding", withExtension: "scn")!
            }
            else {
                url = Bundle.main.url(forResource: "secondBuilding", withExtension: "scn")!
            }
        }
        else {
            url = Bundle.main.url(forResource: thing, withExtension: "scn")
        }
        let referenceNode = SCNReferenceNode(url: url!)!
        referenceNode.position = position
        gameView.scene!.rootNode.addChildNode(referenceNode)
        SCNTransaction.begin()
        referenceNode.load()
        SCNTransaction.commit()
        return referenceNode
    }
    
    //function not used anymore
    func highestAt(x:Float, z:Float, scene: SCNScene) -> SCNNode?{
        var highestNode: SCNNode?
        for node in scene.rootNode.childNodes {
            if node.worldPosition.x == x && node.worldPosition.z == z && node.name != "omni" {
                if let highest = highestNode {
                    if node.worldPosition.y > highest.worldPosition.y {
                        highestNode = node
                    }
                }
                else {
                    highestNode = node
                }
            }
        }
        return highestNode
    }
    
    @objc func screenTapped(recognizer:UIGestureRecognizer) {
        label.text = ""
        guard yourTurn else {label.text = "not your turn"; return}
        let location = recognizer.location(in: gameView)
        let hitresults = gameView.hitTest(location)
        if hitresults.count > 0 { // if something tapped
            let result = hitresults.first
            if let node = result?.node {
                if let name = node.name {
                    // print(name)
                    if setup == false {
                        if gameStatus == .move {
                            //print("locations")
                            // for p in players {
                            //print(p.location)
                            // }
                            let moveCheckResult = moveCheck(name: name, position: node.worldPosition, mode: .move, playerCoords: (player?.node.worldPosition)!)
                            var moveCoords = SCNVector3(0, 0, 0)
                            if moveCheckResult == 1 { // can move and build, is ground
                                moveCoords = SCNVector3(x: node.worldPosition.x, y: node.worldPosition.y + 0.3, z: node.worldPosition.z) // 0.3 is player height
                            }
                            else if moveCheckResult == 2 { // can move, is building
                                // 0.8 = 0.5 building height + 0.3 player height
                                moveCoords = SCNVector3(x: node.worldPosition.x, y: node.worldPosition.y + 0.8, z: node.worldPosition.z)
                            }
                            else {
                                //print("you cannot move there")
                                label.text = "you cannot move there"
                                return
                            }
                            playersBoard[Int(round((player?.location.z)!) + 2)][Int(round((player?.location.x)!)) + 2] = 0
                            movePlayer(to: moveCoords, player: player!)
                            players[player!.id].location = moveCoords
                            playersBoard[Int(round(moveCoords.z) + 2)][Int(round(moveCoords.x)) + 2] = (player?.id ?? 1) + 1
                            var pl: Float?
                            if isOnline == true {
                                pl = Float(yourPlayer)
                                print(moveCoords)
                                let message = ["player" : pl!,
                                               "mode" : 1,
                                               "x" : moveCoords.x,
                                               "y" : moveCoords.y,
                                               "z" : moveCoords.z] as [String : Float]
                                broadcast(message)
                            }
                            //print(playersBoard[0])
                            //print(playersBoard[1])
                            //print(playersBoard[2])
                            //print(playersBoard[3])
                            //print(playersBoard[4])
                            //print("")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                                self.checkVictory()
                            }
                            gameStatus = .build
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                self.updateAvailableMoves(playerCoords: moveCoords)
                            }
                            
                            // move player to slightly adjusted position using move function
                        }
                        else if gameStatus == .build {
                            // when build at wrong spot, skips turn | done
                            //print("locations")
                            for p in players {
                                //print(p.location)
                            }
                            var buildResult = 0
                            let checkResult = moveCheck(name: name, position: node.worldPosition, mode: .build, playerCoords: (player?.node.worldPosition)!)
                            
                            if checkResult > 0 {
                                buildResult = build(name: name, nodeLocation: node.worldPosition)
                            }
                            else {
                                label.text = "you cannot build there"
                                return
                            }
                            print(buildingsBoard[0])
                            print(buildingsBoard[1])
                            print(buildingsBoard[2])
                            print(buildingsBoard[3])
                            print(buildingsBoard[4])
                            print("")
                            var pl: Float?
                            if isOnline == true {
                                pl = Float(yourPlayer)
                                let message = ["player" : pl!,
                                               "mode" : 2,
                                               "x" : node.worldPosition.x,
                                               "y" : node.worldPosition.y,
                                               "z" : node.worldPosition.z] as [String : Float]
                                broadcast(message)
                            }
                            // next turn
                            gameStatus = .move
                            if isOnline == false {
                                if (player?.id ?? 0) + 1 < players.count {
                                    player = players[(player?.id ?? 0) + 1]
                                    playerIndicator.tintColor = colors[player?.id ?? 0]
                                }
                                else {
                                    player = players[0]
                                    playerIndicator.tintColor = colors[0]
                                }
                            }
                            else {
                                if (yourPlayer) + 1 < players.count {
                                    player = players[(yourPlayer) + 1]
                                    playerIndicator.tintColor = colors[yourPlayer + 1]
                                }
                                else {
                                    player = players[0]
                                    playerIndicator.tintColor = colors[0]
                                }
                            }
                            // remove v line for online muliplayer
                            if isOnline == false {
                                updateAvailableMoves(playerCoords: (player?.node.worldPosition)!)
                            }
                            //change all nodes to normal for online multiplayer
                            else {
                                for nod in gameScene.rootNode.childNodes {
                                    if nod.name == "cyanGround" || nod.name == "yellowGround" {
                                        var newNode: SCNNode?
                                        newNode = addNode(position: nod.worldPosition, thing: "ground")
                                        newNode?.name = "ground"
                                        nod.removeFromParentNode()
                                    }
                                    else if nod.name == "cyanBuilding" || nod.name == "yellowBuilding" {
                                        var newNode: SCNNode?
                                        newNode = addNode(position: nod.worldPosition, thing: "thirdBuilding")
                                        newNode?.name = "thirdBuilding"
                                        nod.removeFromParentNode()
                                    }
                                }
                                yourTurn = false
                            }
                        }
                    }
                    else { // for setup
                        if node.name == "ground" {
                            // change to arrays or use moveCheck() | done
                            let loc = SCNVector3(x: node.worldPosition.x, y: node.worldPosition.y + 0.3, z: node.worldPosition.z)
                            guard playersBoard[Int(round(loc.z) + 2)][Int(round(loc.x)) + 2] == 0 else {label.text = "Player \(setupCounter+1), choose your starting position.";return}
                            players.append(Player(node: addPlayer(position: loc, color: colors[setupCounter]), id: setupCounter, location: loc))
                            playersBoard[Int(round(loc.z) + 2)][Int(round(loc.x)) + 2] = (player?.id ?? 1) + 1
                            var pl: Float?
                            if isOnline == true {
                                pl = Float(yourPlayer)
                                let message = ["player" : pl!,
                                               "mode" : 3,
                                               "x" : node.worldPosition.x,
                                               "y" : node.worldPosition.y + 0.3,
                                               "z" : node.worldPosition.z] as [String : Float]
                                broadcast(message)
                            }
                            setupCounter += 1
                            if setupCounter == numPlayers { // start the game
                                player = players[0]
                                setup = false
                                if isOnline == false {
                                    label.text = "Start playing!"
                                    updateAvailableMoves(playerCoords: (player?.node.worldPosition)!)
                                }
                                else {
                                    yourTurn = false
                                    label.text = ""
                                }
                                return
                            }
                        }
                        if isOnline == false {
                            label.text = "Player \(setupCounter+1), choose your starting position."
                        }
                        else {
                            label.text = ""
                            yourTurn = false
                        }
                        playerIndicator.tintColor = colors[setupCounter]
                    }
                }
            }
        }
    }
    
    // change to if move down, move horizontally first and then down | done
    func movePlayer(to: SCNVector3, player: Player) {
        let player = player.node
        
        if to.y != player.worldPosition.y {
            let y = to.y - player.worldPosition.y
            if y > 0 {
                SCNTransaction.animationDuration = 0.5
                player.localTranslate(by: SCNVector3(0, y, 0))
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    SCNTransaction.animationDuration = 1.0
                    player.localTranslate(by: SCNVector3(to.x - player.worldPosition.x, 0, to.z - player.worldPosition.z))
                }
            }
            else if y < 0 {
                SCNTransaction.animationDuration = 0.5
                player.localTranslate(by: SCNVector3(to.x - player.worldPosition.x, 0, to.z - player.worldPosition.z))
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    SCNTransaction.animationDuration = 1.0
                    player.localTranslate(by: SCNVector3(0, y, 0))
                }
            }

        }
        else {
            SCNTransaction.animationDuration = 1.0
            player.localTranslate(by: SCNVector3(to.x - player.worldPosition.x, 0, to.z - player.worldPosition.z))
        }
    }
    
    func build(name: String, nodeLocation: SCNVector3) -> Int {
        // return:
        // 0
        // 1 = dome built
        // 2 = building built
        if name == "building" {
            // if dome
            if nodeLocation.y + 1 >= 3.5 {
                let nod = addNode(position: SCNVector3(x: nodeLocation.x, y: nodeLocation.y + 0.5, z: nodeLocation.z), thing: "dome")
                nod.name = "dome"
                buildingsBoard[Int(round(nod.worldPosition.z)) + 2][Int(round(nod.worldPosition.x)) + 2] += 1
                return 2
            }
            // if building
            else if nodeLocation.y + 1 < 3.5 {
                let nod = addNode(position: SCNVector3(x: nodeLocation.x, y: nodeLocation.y + 1, z: nodeLocation.z), thing: "building")
                buildingsBoard[Int(round(nod.worldPosition.z)) + 2][Int(round(nod.worldPosition.x)) + 2] += 1
                nod.name = "building"
                return 1
            }
        }
        if name == "ground" {
            let nod = addNode(position: SCNVector3(x: nodeLocation.x, y: nodeLocation.y + 0.51, z: nodeLocation.z), thing: "firstBuilding")
            nod.name = "building"
            buildingsBoard[Int(round(nod.worldPosition.z)) + 2][Int(round(nod.worldPosition.x)) + 2] += 1
            return 1
        }
        return 0
    }
    
    func moveCheck(name: String, position: SCNVector3, mode: status, playerCoords: SCNVector3) -> Int {
        // position is position to check
        // return:
        // -1 = player already there
        // 0 = cannot move or build there
        // 1 = can move and build, is ground
        // 2 = is building, can move
        // 3 = is building, can build
        if abs(position.x - playerCoords.x) <= 1 && abs(position.z - playerCoords.z) <= 1 { // if x,z differences within 1
            for p in players {
                if (abs(position.x - p.location.x) < 0.1 && abs(position.z - p.location.z) < 0.1) { // if player (including self) already at position
                    return -1
                }
            }
            if name == "ground" {
                // print(node.worldPosition)
                return 1
            }
            if name == "building" {
                // change next line to check with 2d arrays | done
                if Int(ceil(position.y)) == buildingsBoard[Int(round(position.z))+2][Int(round(position.x))+2] { // checks if pressed is top layer of building
                    if mode == .build {
                        return 3
                    }
                    else if mode == .move && position.y - playerCoords.y <= 1.1 { // check if position is more than one layer above player
                        return 2
                    }
                }
            }
        }
        return 0
    }
    
    // check available using scnvector passed in, not worldcoor of player
    // make more efficient by only regenerating and delting the nodes that are needed
    func updateAvailableMoves(playerCoords: SCNVector3) {
        // print("nodes")
        for nod in gameScene.rootNode.childNodes {
            // print(nod.name as Any)
            // for all precreated ground nodes
            if nod.name == "grounds" {
                for no in nod.childNodes {
                    for n in no.childNodes {
                        updateGroundColor(type: gameStatus, node: n, playerCoords: playerCoords)
                        // print(n.worldPosition)
                    }
                }
            }
            // for newly created ground nodes
            else if nod.name == "ground" || nod.name == "cyanGround" || nod.name == "yellowGround" {
                updateGroundColor(type: gameStatus, node: nod, playerCoords: playerCoords)
            }
            // for buildings (which are newly created)
            else if nod.name == "building" || nod.name == "cyanBuilding" || nod.name == "yellowBuilding" {
                updateBuildingColor(type: gameStatus, node: nod, playerCoords: playerCoords)
            }
        }
    }
    
    func updateGroundColor(type: status, node: SCNNode, playerCoords: SCNVector3){
        var newNode: SCNNode?
        let nodePosition = node.worldPosition
        let checkResults = moveCheck(name: "ground", position: nodePosition, mode: type, playerCoords: playerCoords)
        if checkResults > 0 {
            if type == .move && node.name != "yellowGround" {
                //print("creating yellow ground")
                newNode = addNode(position: nodePosition, thing: "yellowGround")
                newNode?.name = "yellowGround"
                node.removeFromParentNode()
            }
            else if type == .build && node.name != "cyanGround" {
                //print("creating cyan ground")
                newNode = addNode(position: nodePosition, thing: "cyanGround")
                newNode?.name = "cyanGround"
                node.removeFromParentNode()
            }
        }
        else if node.name != "ground" || checkResults == -1 {
            //print("creating ground")
            newNode = addNode(position: nodePosition, thing: "ground")
            newNode?.name = "ground"
            node.removeFromParentNode()
        }
    }
    
    func updateBuildingColor(type: status, node: SCNNode, playerCoords: SCNVector3){
        //print(gameStatus)
        //print(node.worldPosition)
        var newNode: SCNNode?
        let nodePosition = node.worldPosition
        let checkResults = moveCheck(name: "building", position: nodePosition, mode: type, playerCoords: playerCoords)
        if checkResults > 0 {
            if type == .move && node.name != "yellowBuilding" {
                newNode = addNode(position: nodePosition, thing: "yellowBuilding")
                newNode?.name = "yellowBuilding"
                node.removeFromParentNode()
            }
            else if type == .build && node.name != "cyanBuilding" {
                newNode = addNode(position: nodePosition, thing: "cyanBuilding")
                newNode?.name = "cyanBuilding"
                node.removeFromParentNode()
            }
            /*
            else if type == .move && node.name == "cyanBuilding" || type == .build && node .name == "yellowBuilding" {
                newNode = addNode(position: nodePosition, thing: "yellowBuilding")
                newNode?.name = "building"
                node.removeFromParentNode()
            }
             */
        }
        else if node.name != "building" || checkResults == -1 {
            if nodePosition.y >= 1 {
                newNode = addNode(position: nodePosition, thing: "building")
            }
            else {
                newNode = addNode(position: nodePosition, thing: "firstBuilding")
            }
            newNode?.name = "building"
            node.removeFromParentNode()
        }
    }
    
    
    func checkVictory() {
        if player?.node.worldPosition.y ?? 0.3 > 3 {
            for nod in gameScene.rootNode.childNodes {
                if nod.name == "cyanGround" || nod.name == "yellowGround" {
                    var newNode: SCNNode?
                    newNode = addNode(position: nod.worldPosition, thing: "ground")
                    newNode?.name = "ground"
                    nod.removeFromParentNode()
                }
                else if nod.name == "cyanBuilding" || nod.name == "yellowBuilding" {
                    var newNode: SCNNode?
                    newNode = addNode(position: nod.worldPosition, thing: "thirdBuilding")
                    newNode?.name = "building"
                    nod.removeFromParentNode()
                }
                else if nod.name == "omni" || nod.name == "ambient"{
                    nod.removeFromParentNode()
                }
            }
            if isOnline == true {
                broadcast(["player" : String(yourPlayer), "message":"gameWin"])
            }
            else {
                winPlayer = String(yourPlayer + 1)
            }
            saveScene()
            //label.textColor = UIColor.green
            //label.text = "Player \((player?.id ?? -1) + 1) wins!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { // async for waiting for revert colors
                self.performSegue(withIdentifier: "victory", sender: nil)
            }
        }
    }
    
    func saveScene(){
        let sceneToSave = gameScene
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = documentsPath.appendingPathComponent("newscene.scn")
        let pathComponent = url.appendingPathComponent("newscene.scn")
        let filePath = pathComponent.path()
        if FileManager.default.fileExists(atPath: filePath) {
            do{try FileManager.default.removeItem(at: url)}
            catch{print("no item to delete")}
        }
        sceneToSave!.write(to: url, options: nil, delegate: nil, progressHandler: nil)
   }
    
    
    
    func executeAction(action: Dictionary<String, Float>){
        if action["mode"] == 1 {
            player = players[Int(action["player"]!)]
            movePlayer(to: SCNVector3(x: action["x"]!, y: action["y"]!, z: action["z"]!), player: player!)
            gameStatus = .build
        }
        else if action["mode"] == 2{
            player = players[Int(action["player"]!)]
            build(name: "building", nodeLocation: SCNVector3(x: action["x"]!, y: action["y"]!, z: action["z"]!))
            gameStatus = .move
            if Int(action["Player"]!) + 1 == yourPlayer || yourPlayer == 0 && Int(action["Player"]!) + 1 == players.count{
                updateAvailableMoves(playerCoords: players[yourPlayer].location)
            }
        }
        else if action["mode"] == 3{
            let playerLocation = SCNVector3(x: action["x"]!, y: action["y"]!, z: action["z"]!)
            players.append(Player(node: addPlayer(position: playerLocation, color: colors[setupCounter]), id: setupCounter, location: playerLocation))
            setupCounter += 1
        }
    }
    
    func receivedAction(action: String){
        let decodedAction = decodeMessage(message: action)
        guard let decodedAction = decodedAction as? [String:Float] else {return}
        executeAction(action: decodedAction)
    }
    
    /*func sendMessage(message:Encodable){
        let encodedMessage = encodeMessage(message: message)
        print("encoded message")
        print(encodedMessage)
        print("encoded message")
        print(MessageGroupId)
        //SQS().sendMessageFifo(msg: encodedMessage, queueURL: self.myQueueURL, messageDeduplicationID: String(MessageGroupId), deviceID: String(yourPlayer ?? 0))
        MessageGroupId = MessageGroupId + 1
    }*/
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if manager.defaultSocket.status == .connected {
            manager.disconnect()
        }
        let vc = segue.destination as? VictoryViewController
        if isOnline == false {
            vc?.winPlayer = String((player?.id ?? -1) + 1)
        }
        else {
            vc?.winPlayer = winPlayer
        }
        
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    
    func broadcast(_ data: Encodable) {
        let message = encodeMessage(message: data)
        let socket = manager.defaultSocket
        socket.emit("broadcast", message)
        print("sent message: \(message)")
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    
}
