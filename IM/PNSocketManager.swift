//
//  PNSocketManager.swift
//  IM
//
//  Created by apple on 2017/12/12.
//  Copyright © 2017年 Pszertlek. All rights reserved.
//

import UIKit

class PNSocketManager: NSObject {
    static let shared = PNSocketManager()
    var clientSocket = 0
    
    func connect() -> Void {
        
    }
    
    func disConnect() -> Void {
        
    }
    
    func sendMsg(_ msg: String) -> Void {
        
    }
    
    func initSocket() {
        if clientSocket != nil {
            self.disConnect()
            clientSocket = 0
        }
        

    }
    
    static func createClientSocket() -> Int {
        //创建一个socket，返回值为Int。
        //创建一个参数addressFamily IPv4(AF_INET) IPv6(AF_INET6)
        //第二个参数type表示socket的类型，通常是流stream(SOCK_STEAM)或者数据报文datagram(SOCK_DGRAM)
        //第三个参数protocol通常设置为0，以便让系统自动为我们选择合适的协议,对于stream sock来说是TCP协议(IPPROTO_TCP)，对于datagram来说会是UDP协议(IPPROTO_UDP)。
        return Int(socket(AF_INET, SOCK_STREAM, 0))
    }
    
    static func connectToServer(clientSocket: Int,serverIP: String,port: Int16) -> Int {
        var sAddr = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr:in_addr(s_addr: 0) , sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        sAddr.sin_len = UInt8(MemoryLayout.size(ofValue: sAddr))
        sAddr.sin_family = sa_family_t(AF_INET)
        inet_aton(serverIP, &sAddr.sin_addr)
//        sAddr.sin_port = htons()
        if connect() {
            <#code#>
        }
    }
}
