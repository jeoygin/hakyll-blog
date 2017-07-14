---
title: RPC框架系列——Protocol Buffers
tags:
  - Protocol Buffers
  - RPC
  - serialization
id: 446
categories:
  - 计算机技术
  - 网络
date: 2011-09-09 22:08:32
---

**1.下载与安装**

官方网站：http://code.google.com/p/protobuf/

下载地址：http://protobuf.googlecode.com/files/protobuf-2.4.1.tar.bz2

protocol buffers并没有实现RPC通信，可以使用第三方的RPC实现protobuf-socket-rpc，下载地址是：http://protobuf-socket-rpc.googlecode.com/files/protobuf-socket-rpc-2.0.jar

```
cd /usr/local/src
wget http://protobuf.googlecode.com/files/protobuf-2.4.1.tar.bz2
tar jxvf protobuf-2.4.1.tar.bz2
cd protobuf-2.4.1
./configure
make
make check
make install
```

<!--more-->


下面将编译生成jar包，以便在java中使用Protocol Buffers，需确保已安装了maven。

```
cd java
mvn test
mvn install
mvn package
```

安装、编译后在target/目录下会生成protobuf-java-2.4.1.jar。

**2.消息结构与服务接口**

首先需要编写一个.proto文件，结构化数据被称为Message。

```
package protobuf;

option java_package = "protobuf";
option java_outer_classname = "PersonProtos";
option java_generic_services = true;

message Person {
    required string name = 1;
    required int32 id = 2;
    optional string email = 3;

    enum PhoneType {
        MOBILE = 0;
        HOME = 1;
        WORK = 2;
    }

    message PhoneNumber {
        required string number = 1;
        optional PhoneType type = 2 [default = HOME];
    }

    repeated PhoneNumber phone = 4;

    service PhoneService {
        rpc GetPhone (Phone) returns (Phone);
    }
}
```

消息的成员需要指定其规则：

(1) required：这个域在消息中必须刚好有1个；

(2) optional：这个域在消息中可以有0或1个；

(3) repeated：这个域在消息中可以有从多个，包括0个。

Protobuf的类型与Java类型的映射关系：

```
double   ->  double
float    ->  float
int32    ->  int
int64    ->  long
uint32   ->  int[1]
uint64   ->  long[1]
sint32   ->  int
sint64   ->  long
fixed32  ->  int[1]
fixed64  ->  long[1]
sfixed32 ->  int
sfixed64 ->  long
bool     ->  boolean
string   ->  String
bytes    ->  ByteString
```

编写完.proto文件后，就可以使用下面的命令将会在protobuf目录中生成源文件PersonProtos.java

```
protoc –java_out=. person.proto
```

**3.序列化**

先看下面一个例子：

```
message Test1 {
    required int32 a = 1;
}
```

创建一个Test1消息，并且把a设置为150，那么序列化后有如下3个字节：

```
08 96 01
```

**3.1.varint编码**

varint编码的序列化使用一个或多个字节，数字越大使用的字节数越多。对于序列化后的字节，除了最后一个字节，都有一个most significant bit(msb)：表示后边是否有更多的字节。整数序列化时按7位一组，每个字节的低7位保存一组，第一个字节存储最低位一组，即使用little endian。

比如300序列化后的字节序列是：

```
10101100 00000010
```

先去掉每个字节的msb:

```
0101100 0000010
```

交换字节的顺序：

```
0000010 0101100 -> 100101100 -> 256 + 32 + 8 + 4 = 300
```

**3.2.消息结构**

一个protocol buffer message是一个key/value对序列。每一key/value对的key实际是两个值：.proto文件中的field number以及wire type。可用的wire type如下所示：

<table>
<td>Type</td><td>Meaning</td><td>Used For</td>
</hr>
<tr>
<td>0</td><td>Varint</td><td>int32, int64, uint32, uint64, sint32, sint64, bool, enum</td>
</tr>
<tr>
<td>1</td><td>64-bit</td><td>fixed64, sfixed64, double</td>
</tr>
<tr>
<td>2</td><td>Length-delimited</td><td>string, bytes, embedded messages, packed repeated fields</td>
</tr>
<tr>
<td>3</td><td>Start group</td><td>groups (deprecated)</td>
</tr>
<tr>
<td>4</td><td>End group</td><td>groups (deprecated)</td>
</tr>
<tr>
<td>5</td><td>32-bit</td><td>fixed32, sfixed32, float</td>
</tr>
</table>

每一个key是一个varint，值是(field_number << 3) | wire_type，即低三位存储wire type。

**3.3.有符号整数**

有符号整数使用ZigZag编码来将有符号整数映射到无符号整数。

<table>
<td>Signed Original</td><td>Encoded As</td>
</hr>
<tr>
<td>0</td><td>0</td>
</tr>
<tr>
<td>-1</td><td>1</td>
</tr>
<tr>
<td>1</td><td>2</td>
</tr>
<tr>
<td>-2</td><td>3</td>
</tr>
<tr>
<td>2147483647</td><td>4294967294</td>
</tr>
<tr>
<td>-2147483648</td><td>4294967294</td>
</tr>
</table>

**3.4.非varint编码**

```
message Test2 {
    required string b = 2;
}
```

将b的值设置为“testing”，编码结果为：

```
12 07 74 65 73 74 69 6e 67
```

这里的key是0x12：field_number = 2, type = 2。字符串的长度是7。

**3.5.嵌套消息**

```
message Tes3 {
    required Test1 c = 3;
}
```

c的成员a的值设置为150，编码结果为：

```
1a 03 08 96 01
```

后三个字节和Test1一样，之前的数字3表示长度。

**3.5.Repeated域**

```
message Test4 {
    repeated int32 d = 4;
}
```

{3, 270, 86942}编码结果为：

```
22        // tag (field number 4, wire type 2)
06        // payload size (6 bytes)
03        // first element (varint 3)
8E 02     // second element (varint 270)
9E A7 05  // third element (varint 86942)
```

**4.rpc通信实现**

使用protocol buffers的第三方rpc实现protobuf-socket-rpc。

假设protocol buffers生成的类是protobuf. MessageProtos，其中定义了一个消息类Message和一个服务类MessageService，MessageService中定义了一个接口getMessage(RpcController, Message request)。

服务接口实现MessageServiceImpl.java：

```
package protobuf;

import com.google.protobuf.RpcController;
import com.google.protobuf.ServiceException;
import protobuf.MessageProtos.Message;
import protobuf.MessageProtos.MessageService.BlockingInterface;

public class MessageServiceImpl implements BlockingInterface {
    @Override
    public Message getMessage(RpcController controller, Message request)
            throws ServiceException {
        // process request        
……
        return request;
    }
}
```

服务端实现Server.java：

```
package protobuf;

import java.util.concurrent.Executors;

import com.googlecode.protobuf.socketrpc.RpcServer;
import com.googlecode.protobuf.socketrpc.ServerRpcConnectionFactory;
import com.googlecode.protobuf.socketrpc.SocketRpcConnectionFactories;
import protobuf.MessageProtos.MessageService;

public class Server {
    private int port;
    private int threadPoolSize;

    public Server(int port, int threadPoolSize) {
        this.port = port;
        this.threadPoolSize = threadPoolSize;
    }

    public void run() {
        // Start server
        ServerRpcConnectionFactory rpcConnectionFactory = SocketRpcConnectionFactories
                .createServerRpcConnectionFactory(port);
        RpcServer server = new RpcServer(rpcConnectionFactory,
                Executors.newFixedThreadPool(threadPoolSize), true);
        server.registerBlockingService(MessageService
                .newReflectiveBlockingService(new MessageServiceImpl()));
        server.run();
    }

    public static void main(String[] args) {
        if (args.length != 2) {
            System.out.println("Usage: Server port thread_pool_size");
            return;
        }

        int port = Integer.parseInt(args[0]);
        int size = Integer.parseInt(args[1]);

        new Server(port, size).run();
    }
}
```

客户端实现Client.java：

```
package protobuf;

import protobuf.MessageProtos.Message;
import protobuf.MessageProtos.MessageService;
import protobuf.MessageProtos.MessageService.BlockingInterface;

import com.google.protobuf.BlockingRpcChannel;
import com.google.protobuf.ByteString;
import com.google.protobuf.RpcController;
import com.google.protobuf.ServiceException;
import com.googlecode.protobuf.socketrpc.RpcChannels;
import com.googlecode.protobuf.socketrpc.RpcConnectionFactory;
import com.googlecode.protobuf.socketrpc.SocketRpcConnectionFactories;
import com.googlecode.protobuf.socketrpc.SocketRpcController;

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
        // Create channel
        RpcConnectionFactory connectionFactory = SocketRpcConnectionFactories
                .createRpcConnectionFactory(host, port);
        BlockingRpcChannel channel = RpcChannels
                .newBlockingRpcChannel(connectionFactory);

        // Call service
        BlockingInterface service = MessageService.newBlockingStub(channel);
        RpcController controller = new SocketRpcController();
        Message.Builder message = Message.newBuilder();
        // initiate the message
        …

        long start = 0;
        long end = 0;
        try {
            start = System.currentTimeMillis();
            for (int i = 0; i < count; i++) {
                service.getMessage(controller, message.build());
            }
            end = System.currentTimeMillis();
            System.out.println(end - start);
        } catch (ServiceException e) {
            e.printStackTrace();
        }

        // Check success
        if (controller.failed()) {
            System.err.println(String.format("Rpc failed %s : %s",
                    ((SocketRpcController) controller).errorReason(),
                    controller.errorText()));
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

**5.参考资料**

(1) Protocol Buffers Documentation: [http://code.google.com/apis/protocolbuffers/docs/overview.html](http://code.google.com/apis/protocolbuffers/docs/overview.html)
