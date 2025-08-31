//
//  sqs send:receive.swift
//  kitScene
//
//  Created by Matthew Wang on 2024-02-16.
//

import Foundation
import AWSMobileClientXCF
import AWSAuthCore
import AWSSQS

func login(){
    let credentialProvider = AWSCognitoCredentialsProvider(
          regionType: .USEast1,
          identityPoolId: "us-east-1:9721d5b8-7c93-4caf-9e9d-f0778956537c"
    )

    let serviceConfiguration = AWSServiceConfiguration(
          region: .USEast1,
          credentialsProvider: credentialProvider
    )

    AWSServiceManager.default().defaultServiceConfiguration = serviceConfiguration
    
    AWSMobileClient.default().signIn(username: "alxwang@gmail.com", password: "Hjkloopp99*") { (response, error) in
        if let error = error  {
            print("\(error)")
            
        } else if let signInResult = response {
            switch (signInResult.signInState) {
            case .signedIn:
                print("User is signed in.")
            case .smsMFA:
                print("SMS message sent to \(signInResult.codeDetails!.destination!)")
            default:
                print("Sign In needs info which is not yet supported.")
                
            }
            
            // print("here")
        }
        }
    print(AWSMobileClient.default().description)
    print(AWSMobileClient.default().debugDescription)
}

func logout(){
    AWSMobileClient.default().signOut()
    print(AWSMobileClient.default().isLoggedIn)
}
func tset(){}
