---
title: RPC框架系列——MessagePack
tags:
  - MessagePack
  - msgpack
  - RPC
  - serialization
id: 465
categories:
  - 计算机技术
  - 网络
date: 2011-09-11 22:41:26
---

**1.下载与安装**

官方网站：http://msgpack.org/

下载地址：https://github.com/msgpack/msgpack-rpc, https://github.com/msgpack/msgpack

安装之前确保已经装了git和maven

```
cd /usr/local/src
mkdir msgpack
cd msgpack
git clone git://github.com/msgpack/msgpack.git
git clone git://github.com/msgpack/msgpack-rpc.git
cd msgpack/java
mvn package
cd ../../msgpack-rpc/java
mvn package
```

安装成功后，将会在msgpack/msgpack/java/target目录中生成msgpack-0.*.*-devel.jar，会在msgpack/msgpack-rpc/java/target目录中生成msgpack-rpc-0.*.*-devel.jar

<!--more-->

**2.消息结构与服务接口**

定义消息类比较简单，只需要给类加上注解@MessagePackMessage即可。

另一种不添加注解的方法是对类进行注册，如下所示：

```
// You register your class before use.
MessagePack.register(MyClass.class);
```

**3.序列化**

MessagePack在序列化数据中保存类型信息，每个数据以*type-data*或*type-length-data*模式存储。

MessagePack支持以下类型：

定长类型：

Integers：

Nil：

Boolean：

Floating point：

变长类型：

Raw bytes：

容器类型：

Arrays：

Maps：

每种类型有一或多个序列化格式。

**3.1.Integer**

positive fixnum：用1个字节保存一个整数，数值范围为[0,127]。

```
|0XXXXXXX|
=> unsigned 8-bit 0XXXXXXX
```

negative fixnum：用1个字节保存一个整数，数值范围为[-32,-1]。

```
|111XXXXX|
=> signed 8-bit 111XXXXX
```

uint8：用2个字节保存一个8位的unsigned integer。

```
|  0xcc  |XXXXXXXX|
=> unsigned 8-bit XXXXXXXX
```

uint16：用3个字节保存一个16位的unsigned integer。

```
|  0xcd  |XXXXXXXX|XXXXXXXX|
=> unsigned 16-bit big-endian XXXXXXXX_XXXXXXXX
```

uint32：用5个字节保存一个32位的unsigned integer。

```
|  0xce  |XXXXXXXX|XXXXXXXX|XXXXXXXX|XXXXXXXX|
=> unsigned 32-bit big-endian XXXXXXXX_XXXXXXXX_XXXXXXXX_XXXXXXXX
```

uint64：用9个字节保存一个64位的unsigned integer。

```
|  0xcf  |XXXXXXXX| XXXXXXXX | XXXXXXXX | XXXXXXXX | XXXXXXXX | XXXXXXXX | XXXXXXXX | XXXXXXXX |
=> unsigned 64-bit big-endian XXXXXXXX _ XXXXXXXX _ XXXXXXXX _ XXXXXXXX _ XXXXXXXX _ XXXXXXXX _ XXXXXXXX _ XXXXXXXX
```

int8：用2个字节保存一个8位的signed integer。

```
|  0xd0  |XXXXXXXX|
=> signed 8-bit XXXXXXXX
```

int16：用3个字节保存一个16位的signed integer。

```
|  0xd1  |XXXXXXXX|XXXXXXXX|
=> signed 16-bit big-endian XXXXXXXX_XXXXXXXX
```

int32：用5个字节保存一个32位的signed integer。

```
|  0xd2  |XXXXXXXX|XXXXXXXX|XXXXXXXX|XXXXXXXX|
  => signed 32-bit big-endian XXXXXXXX_XXXXXXXX_XXXXXXXX_XXXXXXXX
```

int64：用9个字节保存一个64位的signed integer。

```
|  0xd3  |XXXXXXXX| XXXXXXXX | XXXXXXXX | XXXXXXXX | XXXXXXXX | XXXXXXXX | XXXXXXXX | XXXXXXXX |
=> signed 64-bit big-endian XXXXXXXX _ XXXXXXXX _ XXXXXXXX _ XXXXXXXX _ XXXXXXXX _ XXXXXXXX _ XXXXXXXX _ XXXXXXXX
```

**3.2.Nil**

```
|  0xc0  |
```

**3.3.Boolean**

true:

```
|  0xc3  |
```

false:

```
|  0xc2  |
```

**3.4.Floating point**

float：用5个字节保存。

```
|  0xca  |XXXXXXXX|XXXXXXXX|XXXXXXXX|XXXXXXXX|
=> big-endian IEEE 754 single precision floating point number XXXXXXXX_XXXXXXXX_XXXXXXXX_XXXXXXXX
```

double：用9个字节保存。

```
|  0xcb  |XXXXXXXX| XXXXXXXX | XXXXXXXX | XXXXXXXX | XXXXXXXX | XXXXXXXX | XXXXXXXX | XXXXXXXX |
=> big-endian IEEE 754 single precision floating point number XXXXXXXX _ XXXXXXXX _ XXXXXXXX _ XXXXXXXX _ XXXXXXXX _ XXXXXXXX _ XXXXXXXX _ XXXXXXXX
```

**3.5.Raw bytes**

fix raw：最多保存31个字节。

```
|101XXXXX|...N bytes
=> 000XXXXXX (=N) bytes of raw bytes.
```

raw 16：最多保存(2^16)-1个字节，长度以unsigned 16-bit big-endian integer存储。

```
|  0xda  |XXXXXXXX|XXXXXXXX|...N bytes
=> XXXXXXXX_XXXXXXXX (=N) bytes of raw bytes.
```

raw 32：最多保存(2^32)-1个字节，长度以unsigned 32-bit big-endian integer存储。

```
|  0xdb  |XXXXXXXX|XXXXXXXX|XXXXXXXX|XXXXXXXX|...N bytes
=> XXXXXXXX_XXXXXXXX_XXXXXXXX_XXXXXXXX (=N) bytes of raw bytes.
```

**3.6.Arrays**

fix array：最多保存15个元素。

```
|1001XXXX|...N objects
=> 0000XXXX (=N) elements array.
```

array 16：最多保存 (2^16)-1个元素，元素的数量以unsigned 16-bit big-endian integer存储。

```
|  0xdc  |XXXXXXXX|XXXXXXXX|...N objects
=> XXXXXXXX_XXXXXXXX (=N) elements array.
```

array 32：最多保存 (2^32)-1个元素，元素的数量以unsigned 32-bit big-endian integer存储。

```
|  0xdd  |XXXXXXXX|XXXXXXXX|XXXXXXXX|XXXXXXXX|...N objects
=> XXXXXXXX_XXXXXXXX_XXXXXXXX_XXXXXXXX (=N) bytes of raw bytes.
```

**3.7.Maps**

fix map：最多保存15个元素。

```
|1000XXXX|...N*2 objects
=> 0000XXXX (=N) elements map
   where odd elements are key and next element of the key is its associate value.
```

map16：最多保存 (2^16)-1个元素，元素的数量以unsigned 16-bit big-endian integer存储。

```
|  0xde  |XXXXXXXX|XXXXXXXX|...N*2 objects
=> XXXXXXXX_XXXXXXXX (=N) elements map
   where odd elements are key and next element of the key is its associate value.
```

map32：最多保存 (2^32)-1个元素，元素的数量以unsigned 32-bit big-endian integer存储。

```
|  0xdf  |XXXXXXXX|XXXXXXXX|XXXXXXXX|XXXXXXXX|...N*2 objects
=> XXXXXXXX_XXXXXXXX_XXXXXXXX_XXXXXXXX (=N) elements map
   where odd elements are key and next element of the key is its associate value.
```

**4.rpc通信实现**

定义消息Message.java：

```
package msgpack;

import org.msgpack.annotation.MessagePackMessage;

@MessagePackMessage
public class Message {
    // some attributes
}
```

服务端实现Server.java：

```
package msgpack;

import org.msgpack.rpc.loop.EventLoop;

public class Server {
    private int port;

    public Server(int port) {
        this.port = port;
    }

    public Message getMessage(Message msg) {
// process request
        …
        return msg;
    }

    public void run() {
        try {
            EventLoop loop = EventLoop.defaultEventLoop();

            org.msgpack.rpc.Server svr = new org.msgpack.rpc.Server();
            svr.serve(new Server(port));
            svr.listen(port);

            loop.join();
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
package msgpack;

import java.util.Arrays;
import org.msgpack.rpc.loop.EventLoop;

public class Client {
    private int port;
    private String host;
    private int size;
    private int count;

    public static interface RPCInterface {
        Message getMessage(Message msg);
    }

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
        try {
            EventLoop loop = EventLoop.defaultEventLoop();

            org.msgpack.rpc.Client client = new org.msgpack.rpc.Client(host, port, loop);
            RPCInterface iface = client.proxy(RPCInterface.class);

            Message msg = new Message();
            // initiate message
            …

            start = System.currentTimeMillis();
            for (int i = 0 ; i < count;i++) {
                iface.getMessage(msg);
            }
            end = System.currentTimeMillis();
            System.out.println(end - start);

            client.close();
            loop.shutdown();
        } catch (Exception e) {
            e.printStackTrace();
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

(1) MessagePack QuickStart for Java: [http://wiki.msgpack.org/display/MSGPACK/QuickStart+for+Java](http://wiki.msgpack.org/display/MSGPACK/QuickStart+for+Java)
