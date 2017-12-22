//
//  FayeClient.swift
//  IM
//
//  Created by apple on 2017/12/22.
//  Copyright © 2017年 Pszertlek. All rights reserved.
//

import UIKit
import SocketRocket


public protocol FayeClientDelegate: class {
    func fayeClient(client: FayeClient, didConnectToURL URL: NSURL)
    func fayeClient(client: FayeClient, didDisconnectWithError error:NSError?)
    func fayeClient(client: FayeClient, didSubscribeToChannel channel: String)
    func fayeClient(client: FayeClient, didUnsubscribeFromChannel channel: String)
    func fayeClient(client: FayeClient, didFailWithError error: NSError?)
    func fayeClient(client: FayeClient, didFailDeserilizeMessage message: [String: AnyObject]?, withError error: NSError?)
    func fayeClient(client: FayeClient, didReceiveMessage messageInfo:[String:AnyObject], fromChannel channel:String)
}

public typealias FayeClientSubscriptionHandler = (_ message:[String:AnyObject]) -> Void

public typealias FayeClientPrivateHandler = (_ message:[String:AnyObject]) -> Void

public class FayeClient: NSObject {

    public private(set) var webSocket: SRWebSocket?
    public private(set) var serverURL: NSURL
    public private(set) var clientID: String?
    public private(set) var sentMessageCount: Int = 0
    private var pendingChannelSubscriptionSet: Set<String> = []
    private var openChannelSubscriptionSet: Set<String> = []
    private var subscripbedChannels: [String:FayeClientSubscriptionHandler] = [:]
    private var privateChannels: [String:FayeClientPrivateHandler] = [:]
    private var channelExtensions: [String: AnyObject] = [:]
    
    public var shouldRetyrConnection: Bool = true
    public var retryInterval: TimeInterval = 1
    public var retryAttemp: Int = 0
    public var maximumRetryAttempts: Int = 5
    private var reconnectTimer: Timer?
    public weak var delegate: FayeClientDelegate?
    private var connected: Bool = false
    public var isConnected: Bool {
        return connected
    }
    
    private var isWebSocketOpen: Bool {
        if let webSocket = webSocket {
            return webSocket.readyState == .OPEN
        }
        return false
    }
    
    private var isWebSocketClosed: Bool {
        if let webSocket = webSocket {
            return webSocket.readyState == .CLOSED
        }
        return true
    }
    
    deinit {
        
    }
    public init(serverURL: NSURL) {
        self .serverURL = serverURL
        super.init()
    }
    
    public class func clientWithURL(serverURL: NSURL) -> FayeClient {
        return FayeClient(serverURL: serverURL)
    }
}

extension FayeClient {
    func generateUniqueMessageID() -> String {
        sentMessageCount += 1
        return "\(sentMessageCount)"
    }
}

extension FayeClient {
    public func setExtension(extension: [String: AnyObject], forChannel channel: String) {
        channelExtensions[channel] = `extension` as AnyObject
    }
    
}
