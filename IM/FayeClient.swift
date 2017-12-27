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

// MARK: - Public methods


extension FayeClient {
    public func setExtension(extension: [String: AnyObject], forChannel channel: String) {
        channelExtensions[channel] = `extension` as AnyObject
    }
    
    public func removeExtensionForChannel(channel: String) {
        channelExtensions.removeValue(forKey: channel)
    }
    
    public func sendMessage(message: [String: AnyObject],toChannel channel: String) {
        let messageID = generateUniqueMessageID()
        sendBayeuxPublishMessage(messageInfo: message, withMessageUniqueID: messageID, toChannel: channel, usingExtension: nil)
    }
    
    public func sendMessage(message: [String: AnyObject],toChannel channel: String, usingExtensioin extension: [String: AnyObject]?) {
        let messageID = generateUniqueMessageID()
        sendBayeuxPublishMessage(messageInfo: message, withMessageUniqueID: messageID, toChannel: channel, usingExtension: `extension`)
    }
    
    public func sendMessage(message: [String: AnyObject], toChannel channel: String, usingExtension extension: [String: AnyObject]?, usingBlock subscriptionHandler:@escaping FayeClientPrivateHandler) {
        let messageID = generateUniqueMessageID()
        privateChannels[messageID] = subscriptionHandler
        sendBayeuxPublishMessage(messageInfo: message, withMessageUniqueID: messageID, toChannel: channel, usingExtension: `extension`)
    }
    
    public func connectToURL(serverURL: NSURL) -> Bool {
        if isConnected || isWebSocketOpen {
            return false
        }
        self.serverURL = serverURL
        return connect()
    }
    
    public func connect() -> Bool {
        if isConnected || isWebSocketOpen {
            return false
        }
        
        connectToWebSocket()
        return true
    }
    
    public func disconnect() {
        sendBayeuxDisconnectMessage()
    }
    
    public func subscribeToChannel(_ channel: String) {
        
    }
    
    public func subscribeToChannel(channel: String, usingBlock subscriptionHandler: FayeClientSubscriptionHandler?) {
        if let subscriptionHandler = subscriptionHandler {
            subscripbedChannels[channel] = subscriptionHandler
        } else {
            subscripbedChannels.removeValue(forKey: channel)
        }
        if isConnected {
            sendBayeuxSubscribeMessageWithChannel(channel: channel)
        }
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

// MARK: - Bayeux procotol messages


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
            didFailWithMessage(message: "FayeClient no clientID.")
            return
        }
        var message: [String: AnyObject] = [
            FayeClientBayeuxMessageChannelKey: FayeClientBayeuxChannelConnect as AnyObject,
            FayeClientBayeuxMessageClientIdKey: clientID as AnyObject,
            FayeClientBayeuxMessageConnectionTypeKey: FayeClientBayeuxConnectionTypeWebSocket as AnyObject,
            ]
        if let `extension` = channelExtensions["connect"] {
            message[FayeClientBayeuxMessageExtensionKey] = `extension`
        }
        writeMessage(message)
    }
    
    func sendBayeuxDisconnectMessage() {
        guard let clientID = clientID else {
            didFailWithMessage(message: "FayeClient no clientID.")
            return
        }
        let message: [String: AnyObject] = [
            FayeClientBayeuxMessageChannelKey: FayeClientBayeuxChannelDisconnect as AnyObject,
            FayeClientBayeuxMessageClientIdKey: clientID as AnyObject,
            ]
        writeMessage(message)
        
    }
    
    func sendBayeuxSubscribeMessageWithChannel(channel:String) {
        guard let clientID = clientID else {
            didFailWithMessage(message: "FayeClient no clientID.")
            return
        }
        var message: [String: AnyObject] = [
            FayeClientBayeuxMessageChannelKey: FayeClientBayeuxChannelSubscribe as AnyObject,
            FayeClientBayeuxMessageClientIdKey: clientID as AnyObject,
            FayeClientBayeuxMessageSubscriptionKey: channel as AnyObject,
            ]
        if let `extension` = channelExtensions[channel] {
            message[FayeClientBayeuxMessageExtensionKey] = `extension`
        }
        writeMessage(message) { [weak self] (finish) in
            if finish {
                self?.pendingChannelSubscriptionSet.insert(channel)
            }
        }
    }
    
    func sendBayeuxUnsubscribeMessageWithChannel(channel: String) {
        guard let clientID = clientID else {
            didFailWithMessage(message: "FayeClient no clientID.")
            return
        }
        let message: [String: AnyObject] = [
            FayeClientBayeuxMessageChannelKey: FayeClientBayeuxChannelUnsubscribe as AnyObject,
            FayeClientBayeuxMessageClientIdKey: clientID as AnyObject,
            FayeClientBayeuxMessageSubscriptionKey: channel as AnyObject,
            ]
        writeMessage(message)
    }
    
    func sendBayeuxPublishMessage(messageInfo: [String:AnyObject], withMessageUniqueID message:String, toChannel channel:String, usingExtension extension:[String: AnyObject]?) {
        guard isConnected && isWebSocketOpen else {
            didFailWithMessage(message: "FayeClient no connected to server.")
            return
        }
        guard let clientID = clientID else {
            didFailWithMessage(message: "FayeClient no ClientID.")
            return
        }
        var message: [String: AnyObject] = [
            FayeClientBayeuxMessageChannelKey: channel as AnyObject,
            FayeClientBayeuxMessageClientIdKey: clientID as AnyObject,
            FayeClientBayeuxMessageDataKey: messageInfo as AnyObject,
            FayeClientBayeuxMessageIdKey: message as AnyObject,
            ]
        if let `extension` = `extension` {
            message[FayeClientBayeuxMessageExtensionKey] = `extension` as AnyObject
            
        } else {
            if let `extension` = channelExtensions[channel] {
                message[FayeClientBayeuxMessageExtensionKey] = `extension`
            }
        }
        
        writeMessage(message)
    }
    
    func clearSubscriptions() {
        pendingChannelSubscriptionSet.removeAll()
        openChannelSubscriptionSet.removeAll()
    }
}

// MARK: - Private methods


extension FayeClient {
    private func subscribePendingSubscriptions() {
        for channel in subscripbedChannels.keys {
            if !pendingChannelSubscriptionSet.contains(channel)
                && !openChannelSubscriptionSet.contains(channel) {
                sendBayeuxSubscribeMessageWithChannel(channel: channel)
            }
        }
    }
    
    @objc private func reconnectTimer(timer: Timer) {
        if isConnected {
            invalidateReconnectTimer()
        } else {
            if shouldRetyrConnection && retryAttemp < maximumRetryAttempts {
                retryAttemp += 1
                connect()
            } else  {
                invalidateReconnectTimer()
            }
            
        }
    }
    
    private func invalidateReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    private func reconnect() {
        guard shouldRetyrConnection && retryAttemp < maximumRetryAttempts else {
            return
        }
        reconnectTimer = Timer.scheduledTimer(timeInterval: retryInterval, target: self, selector: #selector(FayeClient.reconnectTimer(timer:)), userInfo: nil, repeats: false)
    }
}
// MARK: - SRWebSocket

extension FayeClient {
    func writeMessage(_ message: [String: AnyObject],completion:((Bool) -> Void)? = nil) {
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
    
    func disconnectFromWebSocket() {
        webSocket?.delegate = nil
        webSocket?.close()
        webSocket = nil
    }
    
    func connectToWebSocket() {
        disconnectFromWebSocket()
        
        let request = URLRequest(url: serverURL as URL)
        webSocket = SRWebSocket(urlRequest: request)
        webSocket?.delegate = self
        webSocket?.open()
    }
    
    func didFailWithMessage(message: String) {
        let error = NSError(domain: FayeClientWebSocketErrorDomain,code: -100, userInfo: [NSLocalizedDescriptionKey:message])
        delegate?.fayeClient(client: self, didFailWithError: error)
    }
    
    func handleFayeMessages(messages: [[String: AnyObject]]) {
//        let fayeMessages = messages.map()??
        //MARK: 没写
    }
}

// MARK: - SRWebSocketDelegate

extension FayeClient: SRWebSocketDelegate {
    public func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        sendBayeuxHandshakeMessage()
    }
    
    public func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        connected = false
        clearSubscriptions()
        delegate?.fayeClient(client: self, didFailWithError: error as! NSError)
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
            if let messages = try JSONSerialization.jsonObject(with: messageData, options: [.allowFragments]) as? [[String: AnyObject]] {
                handleFayeMessages(messages: messages)

            }
        } catch let error  {
            delegate?.fayeClient(client: self, didFailDeserilizeMessage: nil, withError: error as NSError)
        }
    }
    
    public func webSocket(_ webSocket: SRWebSocket!, didReceivePong pongPayload: Data!) {
        
    }
    
    public func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        connected = false
//        clearSubscriptions()
//        let reason = String = reason ?? "Unknown Reason"
        let error = NSError(domain: FayeClientWebSocketErrorDomain, code: code, userInfo:[NSLocalizedDescriptionKey: reason])
    }
}
















