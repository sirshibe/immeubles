//
//  StartViewController.swift
//  kitScene
//
//  Created by Matthew Wang on 2024-01-14.
//

import UIKit


class StartViewController: UIViewController {
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var loadingView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadingView.isHidden = true
        // Do any additional setup after loading the view.
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
        let vc = segue.destination as? GameViewController
        vc?.numPlayers = segmentedControl.selectedSegmentIndex + 2
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }

}
