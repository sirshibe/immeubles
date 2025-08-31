//
//  VictoryViewController.swift
//  kitScene
//
//  Created by Matthew Wang on 2024-01-22.
//  add exit button|done

import UIKit
import SceneKit

class VictoryViewController: UIViewController {

    var gameScene: SCNScene!
    var winPlayer = ""
    var fireworks: SCNParticleSystem?
    let fireworkColors: [UIColor] = [UIColor.red, UIColor.blue, UIColor.yellow, UIColor.orange, UIColor.purple]
    @IBOutlet var label: UILabel!
    @IBOutlet var gameView: SCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gameView.allowsCameraControl = true
        do { try gameScene = SCNScene(url: loadObject()) }
        catch {print("failed to load"); return}
        gameView.scene = gameScene
        gameView.isPlaying = true
        label.text = "Player \(winPlayer) wins!"
        label.textColor = UIColor.green
        for i in 1...30 {
            createFireworks(color: fireworkColors[i%5], location: SCNVector3(x: Float.random(in: -15...15), y: 10, z: Float.random(in: -15...15)), idleTime: CGFloat.random(in: 1...2))
        }
        gameScene.background.contents = UIColor.black
        setupSound()
        // Do any additional setup after loading the view.
    }
    
    func loadObject() -> URL{
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = documentsPath.appendingPathComponent("newscene.scn")
        return url
    }
    
    func createFireworks(color: UIColor, location: SCNVector3, idleTime: CGFloat){
        fireworks = SCNParticleSystem()
        fireworks?.loops = true
        if let fireworks = fireworks {
            fireworks.birthRate = 500
            fireworks.birthRateVariation = 20
            fireworks.particleLifeSpan = 0.5
            fireworks.warmupDuration = 0
            fireworks.loops = true
            fireworks.idleDuration = idleTime
            fireworks.birthLocation = .surface
            fireworks.emitterShape = SCNSphere(radius: 0.1)
            fireworks.birthDirection = .surfaceNormal
            fireworks.particleSize = 0.03
            fireworks.particleVelocity = 4
            fireworks.particleVelocityVariation = 2
            fireworks.emissionDuration = 0.3
            fireworks.particleImage = .none
            fireworks.particleColor = color
            fireworks.stretchFactor = 0.05
            fireworks.speedFactor = 1
        }
        gameScene.addParticleSystem(fireworks!, transform: SCNMatrix4MakeTranslation(location.x, location.y, location.z))
    }
    
    func setupSound() {
        let fireworkSounds = SCNAudioSource(fileNamed: "fireworks.mp3")
        fireworkSounds?.load()
        fireworkSounds?.volume = 1.0
        let musicPlayer = SCNAudioPlayer(source: fireworkSounds!)
        gameScene.rootNode.addAudioPlayer(musicPlayer)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        gameScene.rootNode.removeAllAudioPlayers()
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
}
