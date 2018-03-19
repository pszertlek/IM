//
//  YepFayeService.swift
//  IM
//
//  Created by apple on 2018/2/23.
//  Copyright © 2018年 Pszertlek. All rights reserved.
//

import Foundation

protocol YepFayeServiceDelegate: class {

}

final class YepFayeService: NSObject {
    static let shared = YepFayeService()
    static let fayeQueue = DispatchQueue(label: "com.Yep.fayeQueue")
    enum MessageType: String {
        case Default = "message"
        case Instant = "instant_state"
        case Read = "mark_as_read"
        case MessageDeleted = "message_deleted"
    }
    
    enum InstantStateType: Int, CustomStringConvertible {
        case text = 0
        case audio
        var description: String {
            switch self {
            case .text:
                return NSLocalizedString("typing", comment: "")
            case .audio:
                return NSLocalizedString("recording", comment: "")
            }
        }
    }
    
    let fayeClient: FayeClient = FayeClient(serverURL: fayeBaseURL)
    
    override init() {
        super.init()
    }

}

extension YepFayeService {
//    func prepareFor(channel: String) {
//        if let extensionData = extensionData() {
//            fayeClient.setExtension(extension: extensionData, forChannel: channel)
//        }
//    }
    func sendInstantMessage(message: [String: AnyObject], completion:(Bool) -> Void) {
        YepFayeService.fayeQueue.async { [weak self] in

            
        }
    }
}

//extension YepFayeService {
//    private func extensionData() -> [String: String]? {
//        if let v1AccessToken = YepUserDefaults.v1AccessToken.value {
//            return ["access_token": v1AccessToken, "version": "v1"]
//        }
//    }
//}
//
//
//
//extension YepFayeService: FayeClientDelegate {
//    func fayeClient(_ client: FayeClient, didConnectToURL URL: NSURL) {
//        print("fayeClient didConnectToURL \(URL)")
//        subscribeChannel()
//    }
//}

