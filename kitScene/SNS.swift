//
//  SNS.swift
//  kitScene
//
//  Created by Matthew Wang on 2024-03-13.
//

import Foundation
import AWSCore
import AWSMobileClientXCF
import AWSAuthCore
import AWSSQS
import AWSSNS
import AWSLocationXCF

public class SNS {
    public func postMessageFifo() {
        print("log")
        print(AWSMobileClient.default().isLoggedIn)
        print(AWSMobileClient.default().isSignedIn)
        let sns = AWSSNS.default()
        let input = AWSSNSPublishInput()
        input?.message = "gameStatus-application"
        input?.messageDeduplicationId = "default-group-1"
        input?.messageGroupId = "default-group"
        input?.topicArn = "arn:aws:sns:us-east-1:992382396102:game2.fifo"
        sns.publish(input!) { (result, err) in
            if let result = result {
                print("sucess")
            }
            if let err = err {
                print("SQS sendMessage error: \(err)")
            }
        }
        
    }
}
