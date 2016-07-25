---
title: Socket实现TCP通信
tags:
  - SOCKET
  - TCP
id: 22
categories:
  - 计算机技术
  - 网络
date: 2010-02-10 13:47:10
---

TCP协议本身是与平台无关的，Windows平台能通过TCP协议与Linux平台进行通信，但在不同平台实现网络通信却有些许不同，但过程都大同小异，两个网络程序之间的一个网络连接包括五种信息：通信协议、本地协议地址、本地主机端口、远端主机地址和远端协议端口。主要流程如下：

服务器端的工作流程是这样的：首先创建一个socket，然后将其与本机地址以及一个本地端口号绑定，然后监听socket，当接收到一个连接服务请求时，将生成一个新的socket，之后就可以接收和发送数据。

客户端首先通过服务器域名获得服务器的IP地址，然后创建一个socket与服务器建立连接，连接成功之后就可以接收和发送数据，最后关闭socket。

<!--more-->

**1.windows平台**

a.包含头文件：

```#include <Winsock2.h>```

b.引入库：

```#pragma comment (lib,"ws2_32.lib")```

c.实现代码：

Server:

```
	//要求使用Winsock的最低版本号
	WORD wVersionRequested;
	//Winsock的详细资料
	WSADATA wsaData;
	int err;

	wVersionRequested = MAKEWORD(1,1); //0x0101
	//初始化Winsock
	err = WSAStartup(wVersionRequested,&wsaData);
	if(err!=0)
	{
		return;
	}   

	if(LOBYTE(wsaData.wVersion)!=1 || HIBYTE(wsaData.wVersion)!=1)
	//wsaData.wVersion!=0x0101
	{
		WSACleanup();
		return;
	}   

	//创建Socket
	//SOCK_STREAM : 用于TCP协议
	//SOCK_DGRAM : 用于UDP协议
	SOCKET sockSvr = socket(AF_INET,SOCK_STREAM,0);   

	//创建IP地址和端口
	SOCKADDR_IN addrSvr;
	addrSvr.sin_addr.S_un.S_addr = htonl(INADDR_ANY);
	addrSvr.sin_family = AF_INET;
	addrSvr.sin_port = htons(12345);   

	//绑定端口
	bind(sockSvr,(SOCKADDR*)&amp;addrSvr,sizeof(SOCKADDR));
	//监听socket
	listen(sockSvr,5);   

	sockaddr_in addrClient;
	int len = sizeof(sockaddr);   

	while(true)
	{
		//阻塞方法，获得一个客户Socket连接
		SOCKET sockConn = accept(sockSvr,(sockaddr*)&addrClient,&len);
		char sendbuffer[128];   

		sprintf(sendbuffer,"Welcom %s!",inet_ntoa(addrClient.sin_addr));   

		//向客户端Socket发送数据
		send(sockConn,sendbuffer,strlen(sendbuffer)+1,0);   

		char recvbuffer[128];
		//从客户端Socket接受数据
		memset(recvbuffer,0,sizeof(recvbuffer));
		recv(sockConn,recvbuffer,128,0);   

		printf("%s\n",recvbuffer);   

		//关闭客户端Socket
		closesocket(sockConn);
	}
	//关闭服务器端Socket
	closesocket(sockSvr);

	//释放Winsock资源
	WSACleanup();
```

Client:

```
	//要求使用Winsock的最低版本号
	WORD wVersionRequested;
	//Winsock的详细资料
	WSADATA wsaData;
	int err;

	wVersionRequested = MAKEWORD(1,1); //0x0101
	//初始化Winsock
	err = WSAStartup(wVersionRequested,&wsaData);
	if(err!=0)
	{
		return;
	}   

	if(LOBYTE(wsaData.wVersion)!=1 || HIBYTE(wsaData.wVersion)!=1)
	//wsaData.wVersion!=0x0101
	{
		WSACleanup();
		return;
	}   

	//创建连向服务器的套接字   
	SOCKET sock = socket(AF_INET,SOCK_STREAM,0);   

	//创建地址信息   
	SOCKADDR_IN hostAddr;   
	hostAddr.sin_addr.S_un.S_addr = inet_addr("127.0.0.1");   
	hostAddr.sin_family = AF_INET;   
	hostAddr.sin_port = htons(6000);   

	//连接服务器   
	connect(sock,(sockaddr*)&hostAddr,sizeof(sockaddr));   

	char revBuf[128];   

	//从服务器获得数据
	memset(revBuf,0,sizeof(revBuf));
	recv(sock,revBuf,128,0);   

	printf("%s\n",revBuf);   

	char sendBuf[128];
	//向服务器发送数据   
	scanf("%s",sendBuf);
	send(sock,sendBuf,strlen(sendBuf)+1,0);   

	closesocket(sock);
	//释放Winsock资源
	WSACleanup();
```

**2.linux平台**

待续...
