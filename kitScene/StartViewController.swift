//
//  StartViewController.swift
//  kitScene
//
//  Created by Matthew Wang on 2024-01-14.
//
//  TODO: check if same color has already been chosen by other players

import UIKit


class StartViewController: UIViewController {
    @IBOutlet var loadingView: UIActivityIndicatorView!
    @IBOutlet var capsule1: UIImageView!
    @IBOutlet var capsule2: UIImageView!
    @IBOutlet var capsule3: UIImageView!
    @IBOutlet var capsule4: UIImageView!
    @IBOutlet var colorWell1: UIColorWell!
    @IBOutlet var colorWell2: UIColorWell!
    @IBOutlet var colorWell3: UIColorWell!
    @IBOutlet var colorWell4: UIColorWell!
    @IBOutlet var textField1: UITextField!
    @IBOutlet var textField2: UITextField!
    @IBOutlet var textField3: UITextField!
    @IBOutlet var textField4: UITextField!
    var capsuleColors = [UIColor.systemRed,UIColor.systemBlue,UIColor.systemYellow,UIColor.systemMint]
    var capsule3Enabled = false
    var capsule4Enabled = false
    override func viewDidLoad() {
        super.viewDidLoad()
        loadingView.isHidden = true
        colorWell1.addTarget(self, action: #selector(colorChanged1), for: .valueChanged)
        colorWell2.addTarget(self, action: #selector(colorChanged2), for: .valueChanged)
        colorWell3.addTarget(self, action: #selector(colorChanged3), for: .valueChanged)
        colorWell4.addTarget(self, action: #selector(colorChanged4), for: .valueChanged)
        // Do any additional setup after loading the view.
    }
    
    @IBAction func capsuleButton3(_ sender: Any) {
        if capsule3Enabled{
            capsule3.tintColor = UIColor.systemGray5
            capsule3Enabled = false
        }
        else {
            capsule3.tintColor = capsuleColors[2]
            capsule3Enabled = true
            if colorWell3.selectedColor == nil{
                colorWell3.selectedColor = capsuleColors[2]
            }
        }
    }
    @IBAction func capsuleButton4(_ sender: Any) {
        if capsule4Enabled{
            capsule4.tintColor = UIColor.systemGray5
            capsule4Enabled = false
        }
        else {
            capsule4.tintColor = capsuleColors[3]
            capsule4Enabled = true
            if colorWell4.selectedColor == nil{
                colorWell4.selectedColor = capsuleColors[3]
            }
        }
    }
    
    @objc func colorChanged1(_ sender:UIColorWell){
        capsule1.tintColor=colorWell1.selectedColor
        capsuleColors[0]=colorWell1.selectedColor ?? capsuleColors[0]
    }
    @objc func colorChanged2(_ sender:UIColorWell){
        capsule2.tintColor=colorWell2.selectedColor
        capsuleColors[1]=colorWell2.selectedColor ?? capsuleColors[1]
    }
    @objc func colorChanged3(_ sender:UIColorWell){
        capsule3.tintColor=colorWell3.selectedColor
        capsuleColors[2]=colorWell3.selectedColor ?? capsuleColors[2]
        capsule3Enabled=true
    }
    @objc func colorChanged4(_ sender:UIColorWell){
        capsule4.tintColor=colorWell4.selectedColor
        capsuleColors[3]=colorWell4.selectedColor ?? capsuleColors[3]
        capsule4Enabled=true
    }
    
    @IBAction func startGame(_ sender: Any) {
        loadingView.isHidden = false
        loadingView.startAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.performSegue(withIdentifier: "startGame1", sender: nil)
        }
    }
    
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // TODO: pass updated information
        let vc = segue.destination as? GameViewController
        var playerCount = 4
        var playerNames = [textField1.text ?? "Player 1",textField2.text ?? "Player 2"]
        if !capsule4Enabled {
            playerCount-=1
            capsuleColors.remove(at: 3)
        }
        else {
            playerNames.append(textField4.text ?? "Player 4")
        }
        if !capsule3Enabled {
            playerCount-=1
            capsuleColors.remove(at: 2)
        }
        else {
            playerNames.insert(textField3.text ?? "Player 3", at: 2)
        }
        vc?.numPlayers = playerCount
        vc?.colors = capsuleColors
        vc?.playerNames = playerNames
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }

}
