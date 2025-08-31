//
//  AppDelegate.swift
//  kitScene
//
//  Created by Matthew Wang on 2024-01-07.
//

import UIKit
import AWSCore
import AWSMobileClientXCF
import SocketIO

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let manager = SocketManager(socketURL: URL(string: "ws://ax.ngrok.app")!, config: [.log(true),.compress])

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // AWS SDK logging and debugging
        AWSDDLog.sharedInstance.logLevel = .debug // set to .off for production
        AWSDDLog.add(AWSDDTTYLogger.sharedInstance) // Log to console (TTY = Xcode console)
        
        // Initialize the AWSMobileClient (used for identity management by AWS SDK)
        AWSMobileClient.default().initialize { (userState, error) in
            if let userState = userState {
                print("UserState: \(userState.rawValue)")
            } else if let error = error {
                print("error: \(error.localizedDescription)")
            }
        }
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        ngrok().broadcast(["playerId":UIDevice.current.identifierForVendor!.uuidString, "message":"leaveGame"])
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }


}

