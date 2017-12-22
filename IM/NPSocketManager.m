//
//  NPSocketManager.m
//  IM
//
//  Created by apple on 2017/12/12.
//  Copyright © 2017年 Pszertlek. All rights reserved.
//

/*
 //socket 创建并初始化 socket，返回该 socket 的文件描述符，如果描述符为 -1 表示创建失败。
 int socket(int addressFamily, int type,int protocol)
 //关闭socket连接
 int close(int socketFileDescriptor)
 //将 socket 与特定主机地址与端口号绑定，成功绑定返回0，失败返回 -1。
 int bind(int socketFileDescriptor,sockaddr *addressToBind,int addressStructLength)
 //接受客户端连接请求并将客户端的网络地址信息保存到 clientAddress 中。
 int accept(int socketFileDescriptor,sockaddr *clientAddress, int clientAddressStructLength)
 //客户端向特定网络地址的服务器发送连接请求，连接成功返回0，失败返回 -1。
 int connect(int socketFileDescriptor,sockaddr *serverAddress, int serverAddressLength)
 //使用 DNS 查找特定主机名字对应的 IP 地址。如果找不到对应的 IP 地址则返回 NULL。
 hostent* gethostbyname(char *hostname)
 //通过 socket 发送数据，发送成功返回成功发送的字节数，否则返回 -1。
 int send(int socketFileDescriptor, char *buffer, int bufferLength, int flags)
 //从 socket 中读取数据，读取成功返回成功读取的字节数，否则返回 -1。
 int receive(int socketFileDescriptor,char *buffer, int bufferLength, int flags)
 //通过UDP socket 发送数据到特定的网络地址，发送成功返回成功发送的字节数，否则返回 -1。
 int sendto(int socketFileDescriptor,char *buffer, int bufferLength, int flags, sockaddr *destinationAddress, int destinationAddressLength)
 //从UDP socket 中读取数据，并保存发送者的网络地址信息，读取成功返回成功读取的字节数，否则返回 -1 。
 int recvfrom(int socketFileDescriptor,char *buffer, int bufferLength, int flags, sockaddr *fromAddress, int *fromAddressLength)
 
 */

#import "NPSocketManager.h"
#import <sys/types.h>
#import <netinet/in.h>
#import <sys/socket.h>
#import <arpa//inet.h>

@implementation NPSocketManager {
    int clientSocket;
}

- (void)initSock {
    if (clientSocket != 0) {
        [self disconnect];
        clientSocket = 0;
    }
    
    clientSocket = CreateClientSocket();
}

static int CreateClientSocket() {
    int clientSocket = 0;
    clientSocket = socket(AF_INET, SOCK_STREAM, 0);
    return clientSocket;
}

static int connectToServer(int client_socket,const char * serverIp,unsigned short port) {
    struct sockaddr_in sAddr = {0};
    sAddr.sin_len = sizeof(sAddr);
    sAddr.sin_family = AF_INET;
    
    inet_aton(serverIp, &sAddr.sin_addr);
    sAddr.sin_port = htons(port);
    if (connect(client_socket, &sAddr, sizeof(sAddr)) == 0) {
        return client_socket;
    }
    return 0;
}

- (void)pullMsg {
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(receiveAction) object:nil];
    [thread start];
}



- (void)sendMsg:(NSString *)msg {
    const char *sendMessage = [msg UTF8String];
    send(clientSocket, sendMessage, strlen(sendMessage) + 1, 0);
}

- (void)disconnect {
    close(clientSocket);
}

- (void)connect {
    [self initSock];
}

- (void)receiveAction {
    while (1) {
        char recv_message[1024] = {0};
        recv(clientSocket, recv_message, sizeof(recv_message), 0);
        printf("%s\n",recv_message);
    }
}

@end
