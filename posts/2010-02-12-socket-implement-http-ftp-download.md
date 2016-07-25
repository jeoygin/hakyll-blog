---
title: 用socket实现HTTP、FTP下载
tags:
  - ftp
  - http
  - SOCKET
  - 下载
id: 238
categories:
  - 计算机技术
  - 网络
date: 2010-02-12 19:47:13
---

HTTP和FTP是网络下载的两种主要方式，当前流行的下载软件基本都支持这两种协议，软件提供的WinInet类能很方便地实现HTTP和FTP下载，而我们自己实现下载功能也不难，并且更灵活更具有可扩展性。

之前对HTTP和FTP协议也有所了解，当时在准备全国信息安全竞赛，其中有一个虚拟服务功能，需要对多种请求做出简单应答，实现的是服务端程序；而此次为了完成一个实验，比较HTTP、FTP传送文件的效率，实现的是客户端程序，请求下载服务器上的文件。

<!--more-->

**一．HTTP下载**

对于HTTP协议，向服务器请求某个文件时，只要发送类似如下的请求即可：

```
GET /Path HTTP/1.1
Host: server:port
Accept: */*
User-Agent: DownloadApplication
Connection: close
```

每行用一个&ldquo;回车换行&rdquo;分隔，末尾再追加一个&ldquo;回车换行&rdquo;作为整个请求的结束。

如果服务器成功收到该请求，并且没有出现任何错误，则会返回类似下面的数据：

```
HTTP/1.1 200 OK
Date: Fri, 12 Feb 2010 09:59:00 GMT
Server: Apache/2.2.14 (Win32) PHP/5.2.12
Last-Modified: Sun, 07 Feb 2010 11:42:16 GMT
ETag: "900000001f4c9-400-47f012d31bb3f"
Accept-Ranges: bytes
Content-Length: 1024
Keep-Alive: timeout=5, max=100
Connection: Keep-Alive
Content-Type: text/plain
```

第一行是协议名称及版本号，空格后面会有一个三位数的数字，是HTTP协议的响应状态码，200表示成功，OK是对状态码的简短文字描述。状态码共有5类：1xx属于通知类；2xx属于成功类；3xx属于重定向类；4xx属于客户端错误类；5xx属于服务端错误类。Content-Length字段是一个比较重要的字段，它标明了服务器返回数据的长度，这个长度是不包含HTTP头长度的。如果请求中没有Range字段，表示请求的是整个文件，所以Content-Length就是整个文件的大小。其余各字段是一些关于文件和服务器的属性信息。

返回数据同样是以最后一行的&ldquo;回车换行&rdquo;作为结束，即&ldquo;rnrn&rdquo;。而&ldquo;rnrn&rdquo;后面紧接的就是文件的内容了，读取后续内容并写入文件就实现了文件的下载。

除了下载还不够，还需要实现断点续传，在下载过程中出现错误时能够继续下载，而实现断点下载很简单，只要在请求中加入Range字段即可。假如一个文件有1024个字节，Range的范围是0-1023，&ldquo;Range:bytes=100-&rdquo;表示读取文件的100-1023字节,&ldquo;Range:bytes=100-200&rdquo;表示读取文件的100-200字节。如果HTTP请求中包含Range字段，那么服务器会返回206 Partial Content，同时HTTP头中也会有一个Content-Range字段，如下所示：

Content-Range: bytes 100-200/1024

Content-Range字段说明服务器返回了文件的某个范围及文件的总长度。这时Content-Length字段就不是整个文件的大小了，而是对应文件这个范围的字节数。

部分实现代码：

```
    memset(requestheader,0,sizeof(requestheader));

    ///第行:方法,请求的路径,版本
    strcat(requestheader,"GET ");
    strcat(requestheader,pObject);
    strcat(requestheader," HTTP/1.1");
    strcat(requestheader,"\r\n");

    ///第行:主机
    strcat(requestheader,"Host:");
    strcat(requestheader,pServer);
    strcat(requestheader,"\r\n");

    ///第行:
    if(pReferer != NULL)
    {
        strcat(requestheader,"Referer:");
        strcat(requestheader,pReferer);
        strcat(requestheader,"\r\n");        
    }

    ///第行:接收的数据类型
    strcat(requestheader,"Accept:*/*");
    strcat(requestheader,"\r\n");

    ///第行:浏览器类型
    strcat(requestheader,"User-Agent:GeneralDownloadApplication");
    strcat(requestheader,"\r\n");

    ///第行:连接设置,保持
    strcat(requestheader,"Connection:Keep-Alive");
    strcat(requestheader,"\r\n");

    ///第行:Cookie.
    if(pCookie != NULL)
    {
        strcat(requestheader,"Set Cookie:0");
        strcat(requestheader,pCookie);
        strcat(requestheader,"\r\n");
    }

    ///第行:请求的数据起始字节位置(断点续传的关键)
    if(nFrom >= 0)
    {
        strcat(requestheader,"Range: bytes=");
        _ltoa(nFrom,szTemp,10);
        strcat(requestheader,szTemp);
        strcat(requestheader,"-");
        if(nTo > nFrom)
        {
            _ltoa(nTo,szTemp,10);
            strcat(requestheader,szTemp);
        }
        strcat(requestheader,"\r\n");
    }

    ///最后一行:空行
    strcat(requestheader,"\r\n");

    send(sock, requestheader,strlen(requestheader)+1,0);

```

**二．FTP下载**

客户端和服务器端传送文件，需要有两个socket：控制socket和数据socket，控制socket用来传送命令，数据socket是用于传送数据，比如发送LIST命令回传的数据或是传送文件的数据。主要用到的命令有USER、 PASS、 TYPE、SIZE、REST、CWD、PWD、RETR、PASV、PORT、QUIT。

USER:标记用户。用户命令是访问服务器必须的，此命令通常是控制连接后第一个发出的命令。

PASS:标记用户密码。此命令紧跟USER命令之后。

TYPE:指定表示类型。

SIZE:从服务器上返回指定文件的大小。

REST:代表服务器要重新开始的那一点，此命令并不传送文件，而是略过指定点后的数据，此命令后应该跟其它要求文件传输的FTP命令。 

CWD:此命令使用户可以在不同的目录或数据集下工作而不用改变它的登录或帐户信息。传输参数也不变。参数一般是目录名或与系统相关的文件集合。 

PWD:改变当前的工作目录。 

RETR:开始传送指定的文件。（从REST参数指定的偏移量开始传送） 

PASV:此命令要求服务器DTP在指定的数据端口侦听，进入被动接收请求的状态，参数是主机和端口地址。 

PORT:参数是要使用的数据连接端口，通常情况下对此不需要命令响应。如果使用此命令时，要发送32位的IP地址和16位的TCP端口号。上面的信息以8位为一组，逗号间隔十进制传输。

QUIT:退出登录。

各个参数的具体用法举例如下：

USER rickyrn //用户名为ricky登录

PASS rickyrn //密码为ricky

TYPE Irn 

SIZE file.txtrn //如果file.txt文件存在，则返回该文件的大小

REST 100rn //重新指定文件传送的偏移

CWD /dir/rn //改变当前的工作目录 

PWDrn //获取当前的工作目录 

RETRrn //开始传送文件 

PASVrn //进入被动模式 

PORT h1,h2,h3,h4,p1,p2rn //进入主动模式，h1，h2，h3，h4为ip地址的4个部分。p1，p2是16进制的端口号。

首先，客户端必须和ftp服务器建立连接，利用API函数建立socket连接，然后向服务器发送USER、PASS命令登陆FTP服务器。下载文件时，需要使用CWD命令定位到文件所在的目录，接着使用SIZE命令获取文件的大小，再使用PORT或PASV命令来建立数据连接，这两个命令的区别在于：PORT需要你指定一个IP地址和端口与服务器建立连接；PASV命令服务器会返回h1,h2,h3,h4,p1,p2样式的数据供客户端连接。等数据连接建立后，就可以了使用RETR下载文件。

部分实现代码：

```
    sprintf(sendBuf,"USER %s\r\n",szUsername);
    send(sock,sendBuf,strlen(sendBuf)+1,0);
    recv(sock,recvBuf,sizeof(recvBuf),0);
    ...
    sprintf(sendBuf,"PASS %s\r\n",szPassword);
    send(sock,sendBuf,strlen(sendBuf)+1,0);
    recv(sock,recvBuf,sizeof(recvBuf),0);
    ...
    sprintf(sendBuf,"CWD %s\r\n",szDir);
    send(sock,sendBuf,strlen(sendBuf)+1,0);
    recv(sock,recvBuf,sizeof(recvBuf),0);
    ...
    sprintf(sendBuf,"SIZE %s\r\n",szFile);
    send(sock,sendBuf,strlen(sendBuf)+1,0);
    recv(sock,recvBuf,sizeof(recvBuf),0);
    ...
    sprintf(sendBuf,"PASV\r\n");
    send(sock,sendBuf,strlen(sendBuf)+1,0);
    recv(sock,recvBuf,sizeof(recvBuf),0);
    ...
    sprintf(sendBuf,"RETR %s\r\n", szFile);
    send(sock,sendBuf,strlen(sendBuf)+1,0);
    recv(sock,recvBuf,sizeof(recvBuf),0);
    ...
    While(未下载完毕)
    {
        recv(dataSock,pData,sizeof(pData),0);
        ...
    }
```
