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
    
    public func removeExtensionForChannel(channel: String) {
        channelExtensions.removeValue(forKey: channel)
    }
    
    public func sendMessage(message: [String: AnyObject],toChannel channel: String) {
        let messageID = generateUniqueMessageID()
        sendBayeuxPublishMessage(message, withMessageUniqueID: messageID, toChannel: channel, usingExtension: nil)
    }
    
    public func sendMessage(message: [String: AnyObject],toChannel channel: String, usingExtensioin extension: [String: AnyObject]?) {
        let message = generateUniqueMessageID()
        
        
    }
}


private let FayeClientBayeuxConnectionTypeLongPolling = "long-polling"
private let FayeClientBayeuxConnectionTypeCallbackPolling = "callback-polling"
private let FayeClientBayeuxConnectionTypeIFrame = "iframe";
private let FayeClientBayeuxConnectionTypeWebSocket = "websocket"

private let FayeClientBayeuxChannelHandshake = "/meta/handshake"
private let FayeClientBayeuxChannelConnect = "/meta/connect"
private let FayeClientBayeuxChannelDisconnect = "/meta/disconnect"
private let FayeClientBayeuxChannelSubscribe = "/meta/subscribe"
private let FayeClientBayeuxChannelUnsubscribe = "/meta/unsubscribe"

private let FayeClientBayeuxVersion = "1.0"
private let FayeClientBayeuxMinimumVersion = "1.0beta"

private let FayeClientBayeuxMessageChannelKey = "channel"
private let FayeClientBayeuxMessageClientIdKey = "clientId"
private let FayeClientBayeuxMessageIdKey = "id"
private let FayeClientBayeuxMessageDataKey = "data"
private let FayeClientBayeuxMessageSubscriptionKey = "subscription"
private let FayeClientBayeuxMessageExtensionKey = "ext"
private let FayeClientBayeuxMessageVersionKey = "version"
private let FayeClientBayeuxMessageMinimuVersionKey = "minimumVersion"
private let FayeClientBayeuxMessageSupportedConnectionTypesKey = "supportedConnectionTypes"
private let FayeClientBayeuxMessageConnectionTypeKey = "connectionType"

private let FayeClientWebSocketErrorDomain = "com.nixWork.FayeClient.Error"

extension FayeClient {
    func sendBayeuxHandshakeMessage() {
        let supportedConectionTypes: [String] = [FayeClientBayeuxConnectionTypeLongPolling, FayeClientBayeuxConnectionTypeCallbackPolling, FayeClientBayeuxConnectionTypeIFrame, FayeClientBayeuxConnectionTypeWebSocket,
        ]
        var message: [String: AnyObject] = [
            FayeClientBayeuxMessageChannelKey: FayeClientBayeuxChannelHandshake as AnyObject,
            FayeClientBayeuxMessageVersionKey: FayeClientBayeuxVersion as AnyObject,
            FayeClientBayeuxMessageMinimuVersionKey: FayeClientBayeuxMinimumVersion as AnyObject,
            FayeClientBayeuxMessageSupportedConnectionTypesKey: supportedConectionTypes as AnyObject,
            ]
        if let `extension` = channelExtensions["handshake"] {
            message[FayeClientBayeuxMessageExtensionKey] = `extension`
        }
//        writeMessage(message)
    }
    
    func sendBayeuxConnectMessage() {
        guard let clientID = clientID else {
            
        }
    }
}

extension FayeClient {
    func writeMessage(message: [String: AnyObject],completion:((Bool) -> Void)? = nil) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message, options: JSONSerialization.WritingOptions(rawValue:0))
            let jsonString = String(data: jsonData,encoding:.utf8)
            webSocket?.send(jsonString)
            completion?(true)
        } catch let error as NSError {
            delegate?.fayeClient(client: self, didFailDeserilizeMessage: message, withError: error)
            completion?(true)
        }
    }
    
    func connectToWebSocket() {
        disconnectFromWebSocket()
        
        let request = URLRequest(u)
    }
}

extension FayeClient: SRWebSocketDelegate {
    public func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        sendBayeuxHandshakeMessage()
    }
    
    public func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        connected = false
        clearSubscriptions()
        delegate?.fayeClient(client: self, didFailWithError: error)
        reconnect()
    }
    
    public func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        guard let message = message else {
            return
        }
        
        var _messageData: Data? = nil
        if let messageString = message as? String {
            _messageData = messageString.data(using: .utf8)
        } else {
            _messageData = message as? Data
        }
        guard let messageData = _messageData else {
            return
        }
        do {
            if let messages = try JSONSerialization.jsonObject(with: messageData, options: [.allowFragments]) {
                handleFayeMessages(messages)

            }
        } catch let error  {
            delegate?.fayeClient(client: self, didFailDeserilizeMessage: nil, withError: error as NSError)
        }
    }
    
    public func webSocket(_ webSocket: SRWebSocket!, didReceivePong pongPayload: Data!) {
        
    }
    
    public func webSocketShouldConvertTextFrame(toString webSocket: SRWebSocket!) -> Bool {
        
    }
    
    public func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        connected = false
//        clearSubscriptions()
//        let reason = String = reason ?? "Unknown Reason"
        let error = NSError(domain: FayeClientWebSocketErrorDomain, code: code, userInfo:[NSLocalizedDescriptionKey: reason])
    }
}
















