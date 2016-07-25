---
title: RPC框架系列——Thrift
tags:
  - RPC
  - serialization
  - Thrift
id: 462
categories:
  - 计算机技术
  - 网络
date: 2011-09-11 22:37:58
---

**1.下载与安装**

官方网站：http://thrift.apache.org/

下载地址：http://labs.renren.com/apache-mirror//thrift/0.6.1/thrift-0.6.1.tar.gz

安装Thrift：

```
cd /usr/local/src
wget http://labs.renren.com/apache-mirror//thrift/0.6.1/thrift-0.6.1.tar.gz
tar zxvf avro-src-1.5.1.tar.gz
cd thrift-0.6.1
./configure
make
make install
```

进入lib/java目录，执行以下命令编译并生成jar包，请确保已经安装了ant和maven.

```
ant
```

安装后，libthrift-0.6.1-snapshot.jar位于thrift-0.6.1/lib/java/build目录

<!--more-->

**2.消息结构与服务接口**

基本数据类型：

```
bool: A boolean value (true or false)
byte: An 8-bit signed integer
i16: A 16-bit signed integer
i32: A 32-bit signed integer
i64: A 64-bit signed integer
double: A 64-bit floating point number
string: A text string encoded using UTF-8 encoding
```

特殊数据类型：

```
binary: a sequence of unencoded bytes. Translates to a Java ByteBuffer
```

容器：

```
list<type>: An ordered list of elements. Translates to a Java ArrayList
set<type>: An unordered set of unique elements. Translates to a Java HashSet
map<type1,type2>: A map of strictly unique keys to values. Translates to a Java HashMap
```

首先需要编写一个.thrift文件，定义一个消息结构。如下是message.thrift文件内容：

```
namespace java thrift

struct Message {
    1: string name,
    2: i32 type,
    3: double price,
    4: bool valid,
    5: binary content
}

service MessageService {
    Message getMessage(1:Message msg)
}
```

其中定义了1个结构叫做Message，位于包thrift中，有5个成员name、type、price、valid、content。还定义了1个服务叫做MessageService，其中有一个getMessage方法，需要输入一个参数，类型是message，返回值类型是message。

编写完message.thrift文件后，执行以下命令，将会gen-java目录中生成相应的java文件，类MessageService的包是thrift。

```
thrift --gen java message.thrift
```

**3.rpc通信实现**

Thrift会生成结构类和服务类，假设生成的类分别是Message和MessageService，MessageService中定义了服务getMessage(Message msg)。

服务接口实现MessageServiceImpl.java：

```
package thrift;

import org.apache.thrift.TException;
import thrift.MessageService.Iface;

public class MessageServiceImpl implements Iface {

    @Override
    public Message getMessage(Message msg) throws TException {
// process the message
        …
        return msg;
    }

}
```

服务端实现Server.java：

```
package thrift;

import org.apache.thrift.protocol.TBinaryProtocol;
import org.apache.thrift.protocol.TBinaryProtocol.Factory;
import org.apache.thrift.server.TServer;
import org.apache.thrift.server.TThreadPoolServer;
import org.apache.thrift.transport.TServerSocket;

public class Server {
    private int port;

    public Server(int port) {
        this.port = port;
    }

    public void run() {
        try {
            TServerSocket serverTransport = new TServerSocket(port);
            MessageService.Processor processor = new MessageService.Processor(
                    new MessageServiceImpl());
            Factory protFactory = new TBinaryProtocol.Factory(true, true);
            TThreadPoolServer.Args args = new TThreadPoolServer.Args(
                    serverTransport);
            args.processor(processor);
            args.protocolFactory(protFactory);
            TServer server = new TThreadPoolServer(args);
            server.serve();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
        if (args.length != 1) {
            System.out.println("Usage: Server port");
            return;
        }
        int port = Integer.parseInt(args[0]);
        new Server(port).run();
    }
}
```

客户端实现Client.java：

```
package thrift;

import java.nio.ByteBuffer;
import java.util.Arrays;

import org.apache.thrift.protocol.TBinaryProtocol;
import org.apache.thrift.protocol.TProtocol;
import org.apache.thrift.transport.TSocket;
import org.apache.thrift.transport.TTransport;

public class Client {
    private int port;
    private String host;
    private int size;
    private int count;

    public Client(int port, String host, int size, int count) {
        super();
        this.port = port;
        this.host = host;
        this.size = size;
        this.count = count;
    }

    public long run() {
        long start = 0;
        long end = 0;
        TTransport transport = null;
        try {
            transport = new TSocket(host, port);
            TProtocol protocol = new TBinaryProtocol(transport);
            MessageService.Client client = new MessageService.Client(protocol);
            transport.open();

            Message message = new Message();
            // initiate the message
            …

            start = System.currentTimeMillis();
            for (int i = 0; i < count; i++) {
                client.getMessage(message);
            }
            end = System.currentTimeMillis();
            System.out.println(end - start);
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            if (transport != null) {
                transport.close();
            }
        }

        return end - start;
    }

    public static void main(String[] args) {
        if (args.length != 4) {
            System.out.println("Usage: Client host port dataSize count");
            return;
        }
        String host = args[0];
        int port = Integer.parseInt(args[1]);
        int size = Integer.parseInt(args[2]);
        int count = Integer.parseInt(args[3]);

        new Client(port, host, size, count).run();
    }
}
```

**4.参考资料**

(1) Thrift wiki: [http://wiki.apache.org/thrift/](http://wiki.apache.org/thrift/)
