---
title: gzip格式介绍
tags:
  - code
  - Compression
  - deflate
  - format
  - gzip
  - Huffman
  - LZ77
id: 858
categories:
  - 计算机技术
  - 算法与数据结构
date: 2012-05-10 13:09:30
---

## 概述 ##

gzip是GNU zip的缩写，是一个GNU自由软件的文件压缩程序，也经常用来表示gzip这种文件格式。软件的作者是Jean-loup Gailly和Mark Adler。1992年10月31日第一次公开发布，版本号是0.1，目前最新的稳定版本是1.4。

gzip的基础是DEFLATE，DEFLATE是LZ77与哈夫曼编码的一个组合体。DEFLATE最初是作为LZW以及其它受专利保护的数据压缩算法的替代版本而设计的，当时那些专利限制了compress以及其它一些流行的归档工具的应用。

需要注意的是，gzip仅对单个文件进行压缩，不具备打包归档功能，一般先通过外部归档工具将文件/目录打包后再使用gzip进行压缩。另一种压缩格式zip也使用DEFLATE算法，而且可移植性更好，并且不需要一个外部的归档工具就可以包容多个文件。

HTTP/1.1协议允许客户端可以选择要求从服务器下载压缩内容，这个标准本身定义了两种压缩方法：“gzip”（内容用gzip数据流进行封装）以及“deflate”（内容是原始格式、没有数据头的DEFLATE数据流）。许多HTTP客户端库以及绝大多数当今的浏览器都支持这两种格式。

<!--more-->

## gzip格式 ##

gzip是一种无损的压缩数据格式：

* 与CPU类型、操作系统、文件系统、字符集独立；
* 能压缩或解压缩一个数据流来产生另一个数据流；
* 能够容易地以不受专利保护的方式实现，因此能够自由地实践；
* 和广泛使用的gzip程序产生的文件格式兼容，因为遵照标准的解压缩器能够读取由存在的gzip压缩器产生的数据。

gzip数据格式不并为了：

* 提供对压缩数据的随机访问；
* 压缩特定的数据。

**总体约定：**

在下文中，

```
 +---+
 |   |
 +---+
```

表示一个字节，一个字节表示0-255的整数；而

```
 +==============+
 |              |
 +==============+
```

表示不定数量的多个字节，对于单个节点的表示，最高有效位（most significant bit）在左边，最低有效位（least significant bit）在右边，如下所示：

```
 +--------+
 |76543210|
 +--------+
```

在计算机中，一个数据可能会占用多个字节 ，所有多字节数据采用小端（Little Endian）表示，即最低有效字节（least significant byte）在前。比如数字520的表示：

```
 +--------+--------+
 |00001000|00000010|
 +--------+--------+
```

最高有效字节（most significant byte）为00000010，最低有效字节为00001000，那么表示的整数是2*256+8=520。

**文件格式：**

一个gzip文件由一系列member（压缩数据集）组成，在文件中，member一个挨着一个排放，在member前面、中间和后面没有额外的信息。

**member格式：**

每个member有以下的结构：

```
 +---+---+---+---+---+---+---+---+---+---+
 |ID1|ID2|CM |FLG|     MTIME     |XFL|OS | (more-->)
 +---+---+---+---+---+---+---+---+---+---+
```

之后紧跟的内容取决于FLG，如果设置了FLG.FEXTRA：

```
 +---+---+=================================+
 | XLEN  |...XLEN bytes of "extra field"...| (more-->)
 +---+---+=================================+
```

如果设置了FLG.FNAME：

```
 +=========================================+
 |...original file name, zero-terminated...| (more-->)
 +=========================================+
```

如果设置了FLG.FCOMMENT：

```
 +===================================+
 |...file comment, zero-terminated...| (more-->)
 +===================================+
```

如果设置了FLG.FHCRC：

```
 +---+---+
 | CRC16 |
 +---+---+

 +=======================+
 |...compressed blocks...| (more-->)
 +=======================+

   0   1   2   3   4   5   6   7
 +---+---+---+---+---+---+---+---+
 |     CRC32     |     ISIZE     |
 +---+---+---+---+---+---+---+---+
```

其中：

* ID1表示IDentification 1。
* ID2表示IDentification 2。
    * 以上两个域有固定的值，ID1 = 31 (0x1f, \037)，ID2 = 139 (0x8b, \213)，用以标识gzip格式。
* CM表示Compression Method，即压缩方法，CM = 0-7被保留，CM = 8表示"deflate"压缩方法。
* FLG 表示FLaGs，这个字节被分成以下几个不同的位：
    * bit 0   FTEXT：如果设置了FTEXT，这个文件可能是ASCII文本。
    * bit 1   FHCRC：如果设置了FHCRC，那么在压缩数据之前会有一个gzip头部的CRC16值，CRC16包含gzip头部（不包括CRC16）的CRC32值的两个最低有效位。
    * bit 2   FEXTRA：如果设置了FEXTRA，表示有可选的附加域。
    * bit 3   FNAME：如果设置了FNAME，表示有原始文件名，文件名以一个字节0结束；名字必须包含ISO 8859-1 (LATIN-1)字符，如果使用其它字符集来命令文件，需要先把名字转成ISO LATIN-1字符集；如果文件存在于一个对文件名大小写敏感的文件系统中，强制转成小写；如果被　压缩的数据来自某个数据源而不是命名的文件，比如Unix系统中的stdin，那么没有原始文件名这个域。
    * bit 4   FCOMMENT：如果设置了FCOMMENT，表示有以字节0结束的文件注释，注释由ISO 8859-1 (LATIN-1)字符组成，换行使用一个换行符0x0a。
    * bit 5   reserved：设置为0。
    * bit 6   reserved：设置为0。
    * bit 7   reserved：设置为0。
* MTIME表示Modification TIME：即原始文件的最近修改时间，时间采用Unix格式，计算自1970年1月1日经历的秒数，如果压缩数据不是来自一个文件，时间设置为压缩开始的时间，MTIME = 0表示没有可用的时间戳。
* XFL表示eXtra FLags，这些标记用于特定的压缩方法，"deflate"方法标记的设置如下：
    * XFL = 2：使用压缩比最高、速度最慢的算法
    * XFL = 4：使用速度最快的算法
* OS表示Operating System，标识文件系统的类型，当前定义的值如下：
    * 0 - FAT filesystem (MS-DOS, OS/2, NT/Win32)
    * 1 - Amiga
    * 2 - VMS (or OpenVMS)
    * 3 - Unix
    * 4 - VM/CMS
    * 5 - Atari TOS
    * 6 - HPFS filesystem (OS/2, NT)
    * 7 - Macintosh
    * 8 - Z-System
    * 9 - CP/M
    * 10 - TOPS-20
    * 11 - NTFS filesystem (NT)
    * 12 - QDOS
    * 13 - Acorn RISCOS
    * 255 - unknown
* XLEN表示eXtra Length，如果设置了FLG.FEXTRA，这个域将给出可选的附加域的长度。
* CRC32表示Cyclic Redundancy Check，这个域的值是对未压缩数据采用CRC-32算法计算出来的值。
* ISIZE表示Input SIZE，这个域的值是原始输入数据的大小模2^32。

由上，我们知道如果设置了FLG.FEXTRA，那么在member的头部会出现附加域，附加域由一系列子域组成，每个子域的结构如下：

```
 +---+---+---+---+==================================+
 |SI1|SI2|  LEN  |... LEN bytes of subfield data ...|
 +---+---+---+---+==================================+
```

其中SI1和SI2构成子域的ID，通常是两个ASCII字符；LEN给出了子域数据的长度。目前定义的附加域有：

* AC (0x41, 0x43) : Acorn RISC OS/BBC MOS file type information
* Ap (0x41, 0x70) : Apollo file type information
* cp (0x63, 0x70) : file compressed by cpio
* GS (0x1D, 0x53) : gzsig
* KN (0x4b, 0x4e) : KeyNote assertion (RFC 2704)
* Mc (0x4d, 0x63) : Macintosh info (Type and Creator values)
* RO (0x52, 0x4F) : Acorn Risc OS file type information

## deflate压缩数据格式 ##

了解gzip格式后，我们知道当前gzip使用deflate方法来压缩数据，那好，下面就对DEFLATE压缩数据的格式进行分析。

deflate是一种无损压缩数据格式，结合LZ77算法和Huffman（哈夫曼）编码对数据进行压缩。这种格式能以不被专利保护的方式任意实现。

没有无损压缩算法能压缩任何可能的输入数据集，对于deflate格式，压缩后的数据可能会比原始数据大，最坏的情况下是32KB的数据块膨胀5字节，比如压缩大数据集压缩后的大小比原始数据增大0.015%。英文文本通常能压缩到原始数据的30%-40%。

一个压缩数据集包含一系列的block（块），只要未压缩数据大小不超过65535字节，块的大小是任意的。每个块结合LZ77算法和Huffman编码进行压缩：每个块的Huffman树独立于其之前或随后的块；LZ77算法可以使用在当前块之前出现的重复字符串的引用，但仅限在之前32K输入字符以内。

每个block由两部分组成：一对描述压缩数据表示的Huffman编码树以及压缩数据。压缩数据由一系列的element组成，element有两种类型：literal（原封不动的字节，在之前的32K输入字节里没有检测到重复的串）和pointer（指向重复串的指针，表示为<length, backward distance>，即串的长度以及回退的距离，长度的限制是256字节，距离的限制是32K字节）。压缩数据中每种类型的值（literal、distance和length）使用Huffman编码来表示，使用一棵编码树表示literal和length，另一棵单独的编码树表示distance，每一个block的编码树出现在压缩数据之前，两者紧挨着。

对于下面图表的约定可见“gzip格式”一节。

**prefix编码和Huffman编码：**

prefix（前缀）编码表示一个先验的已知的位序列字母表中的符号，每个符号一个编码，不同的符号可能被表示成不同长度的位序列。我们根据如下所示的二叉树来定义编码，每个非叶子节点的两条边被标记为0和1，而叶子节点和字节表中的符号一一对应，那么一个符号的编码就是从根节点到叶子节点路径上所有边的标号序列。

```
                  /\              Symbol    Code
                 0  1             ------    ----
                /    \                A      00
               /\     B               B       1
              0  1                    C     011
             /    \                   D     010
            A     /\
                 0  1
                /    \
               D      C
```

解析器只要在上面所示的二叉树上从根往下走，就能从一个已编码的输入流中对每个符号进行解码，每次根据下一个输入位来选择相应的边。

Huffman算法能够构建一个最佳的prefix编码。

**Huffman编码在deflate格式中的使用：**

在deflate格式中用于每个字母表的Huffman编码有两条额外的规则：

* 所有指定位长度的编码有字典序连续的值，顺序和它们表示的符号一致；
* 短的编码按字典序先于长的编码。

我们来看下面的例子：

```
    Symbol  Code
    ------  ----
    A       10
    B       0
    C       110
    D       111
```

0先于10，10先于11x，110和111是字典序连续。

有了上面的约束，我们能根据给定的字母表中每个符号的编码的位长度来定义字母表的Huffman编码。以下的算法会生成整数编码，编码的长度初始化在tree[I].Len中，生成的编码放在tree[I].Code中：

1) 计算每个编码长度的编码数量，令bl_count[N]为长度N的编码数量，N >= 1。

2) 找到每个编码长度的最小编码的数值：

```
     code = 0;
     bl_count[0] = 0;
     for (bits = 1; bits <= MAX_BITS; bits++) {
         code = (code + bl_count[bits-1]) << 1;
         next_code[bits] = code;
     }
```

3) 分配数值给所有的编码，对于相同长度的编码，使用连续的值：

```
     for (n = 0;  n <= max_code; n++) {
         len = tree[n].Len;
         if (len != 0) {
             tree[n].Code = next_code[len];
             next_code[len]++;
         }
     }
```

假设有一个字母表ABCDEFGH，位长度分别为（3, 3, 3, 3, 3, 2, 4, 4），完成步骤1后,有：

```
 N      bl_count[N]
 -      -----------
 2      1
 3      5
 4      2
```

步骤2计算出以下的next_code值：

```
 N      next_code[N]
 -      ------------
 1      0
 2      0
 3      2
 4      14
```

步骤3产生以下的编码值：

```
 Symbol Length   Code
 ------ ------   ----
 A       3        010
 B       3        011
 C       3        100
 D       3        101
 E       3        110
 F       2         00
 G       4       1110
 H       4       1111
```

**块的格式：**

每个压缩数据块以如下表示的3个头部位（header bit）开始，头部位不要求从一个字节的边界开始，因为一个压缩数据块不一定占用完整的字节：

* 第一位表示BFINAL，如果当前块是数据集的最后一块，将BFINAL设置为1.
* 剩下两位表示BTYPE，指定以何种方式压缩数据：
    * 00：没有压缩
    * 01：使用固定的Huffman编码压缩
    * 10：使用动态的Huffman编码压缩
    * 11：保留（错误）

两种压缩方式的唯一不同是Huffman编码的定义，但解码算法是一致的：

```
 do
     从输入流中读取块的头部
     if (没对数据进行压缩)
         跳过当前处理字节的剩余位
         读取LEN和NLEN（见下文）
         拷贝LEN字节数据到输出
     else
         如果使用动态Huffman编码压缩
             读取编码树的表示
         loop (直到块编码的结束)
             从输入流对literal/length value进行解码
             if (value < 256)
                 拷贝value（literal）到输出流
             else
                 if (value = 256)
                     退出loop
                 else (value = 257...285)
                     从输入流中对distance进行解码

                     在输出流中往前回退distance个字节，
                     在当前位置拷贝length个字节到输出流
         end loop
 while (不是最后一块)
```

注意，一个重复的字符串引用可能会指向之前一个块的一个串，回退的距离可能会跨越一个或多个块边界，但是不能超过输出流的开端。

**未压缩块（BTYPE=00）：**

到下一字节边界之间任意位会被忽略，块剩下的部分包含以下信息：

```
      0   1   2   3   4...
    +---+---+---+---+================================+
    |  LEN  | NLEN  |... LEN bytes of literal data...|
    +---+---+---+---+================================+
```

LEN是压缩块中数据的大小，NLEN是LEN的补充。

**压缩块（length和distance编码）：**

在deflate格式中的编码数据块由一系列符号组成，这些符号取自三个概念上不同的字母表。对于literal，取值范围是(0..255)；而<length, backward distance>对，length的取值范围是(3..258)，distance的取值范围是(1..32768)。事实上，literal和length字母表被合并到一个单一的字母表(0..285)，其中值0..255表示literal，值256表示块的结束，值257..285表示length编码（可能会结合附加位来表示实际的length）：

```
         Extra               Extra               Extra
    Code Bits Length(s) Code Bits Lengths   Code Bits Length(s)
    ---- ---- ------     ---- ---- -------   ---- ---- -------
     257   0     3       267   1   15,16     277   4   67-82
     258   0     4       268   1   17,18     278   4   83-98
     259   0     5       269   2   19-22     279   4   99-114
     260   0     6       270   2   23-26     280   4  115-130
     261   0     7       271   2   27-30     281   5  131-162
     262   0     8       272   2   31-34     282   5  163-194
     263   0     9       273   3   35-42     283   5  195-226
     264   0    10       274   3   43-50     284   5  227-257
     265   1  11,12      275   3   51-58     285   0    258
     266   1  13,14      276   3   59-66
```

附加位解释为一个左边为高位的整数，比如1110表示数值14。

distance的表示如下：

```
          Extra           Extra               Extra
     Code Bits Dist  Code Bits   Dist     Code Bits Distance
     ---- ---- ----  ---- ----  ------    ---- ---- --------
       0   0    1     10   4     33-48    20    9   1025-1536
       1   0    2     11   4     49-64    21    9   1537-2048
       2   0    3     12   5     65-96    22   10   2049-3072
       3   0    4     13   5     97-128   23   10   3073-4096
       4   1   5,6    14   6    129-192   24   11   4097-6144
       5   1   7,8    15   6    193-256   25   11   6145-8192
       6   2   9-12   16   7    257-384   26   12  8193-12288
       7   2  13-16   17   7    385-512   27   12 12289-16384
       8   3  17-24   18   8    513-768   28   13 16385-24576
       9   3  25-32   19   8   769-1024   29   13 24577-32768
```

**使用固定Huffman编码压缩（BTYPE=01）：**

两个字母表的Huffman编码是固定的，并且不在数据中显式地表示，对于listeral/length的Huffman编码长度如下：

```
           Lit Value    Bits        Codes
           ---------    ----        -----
             0 - 143     8          00110000 through
                                    10111111
           144 - 255     9          110010000 through
                                    111111111
           256 - 279     7          0000000 through
                                    0010111
           280 - 287     8          11000000 through
                                    11000111
```

以上描述的编码长度足以生成真实的编码，literal/length的值286-287将不会在压缩数据中出现，但参与到编码的构建。

distance编码0-31由5位编码来表示,可能的附加位的长度如前文所示。需要注意的是distance编码30-31在压缩数据中不会出现。

**使用动态Huffman编码压缩（BTYPE=10）：**

在压缩块中出现的两个字母表的Huffman编码紧跟在块头部之后，在真实的压缩数据之前，首先是literal/length编码，然后是distance编码，每个编码的定义在前文已经介绍过，为了使编码更加紧凑，编码本身也使用Huffman编码进行压缩，这些编码下文称为Code Length，Code Length的字母表如下所示：

```
       0 - 15: 表示Code Length 0-15。
           16: 拷贝前面的编码3到6次。
               接下来的两位表示重复的次数
                     （0 = 3，1 = 4，2 = 5，3 = 6）
                  例子：编码8，16（额外两位：11），
                       16（额外两位：10）将拓展为
                       12个“Code Length 8”（1 + 6 + 5）
           17: 重复“Code Length 0”3到10次（重复次数占后面的三位）。
           18: 重复“Code Length 0”11到138次（重复次数占后面的七位）。
```

Code Length 0表示在literal/length或distance字母表中对应的符号不会在块中出现，并且不应参与前面给出的Huffman编码构建算法。如果只有一个distance编码被使用，那么使用1位来编码，而不是0位。一个0位的distance编码意味着没有使用distance编码（数据全是literal）。

现在我们可以定义块的格式：

```
       5 Bits: HLIT, Literal/Length编码数量 - 257 (257 - 286)
       5 Bits: HDIST, Distance编码数量 - 1        (1 - 32)
       4 Bits: HCLEN, Code Length编码数量 - 4     (4 - 19)
       (HCLEN + 4) x 3 bits: 用Code Length字母表的Code Length,
          按以下的顺序排列: 16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 
          4, 12, 3, 13, 2, 14, 1, 15。          
          这些Code Length被解释为3位的整数（0-7），Code Length 0表示对应的符号没被使用

       HLIT + 257个用于literal/length字母表的编码，
          使用Code Length Huffman编码

       HDIST + 1个用于distance字母表的编码，
          使用Code Length Huffman编码

       块的真实压缩数据使用literal/length和distance Huffman编码

       literal/length编码256 (数据末尾)使用literal/length Huffman编码
```

**压缩算法细节：**

当压缩器认为使用新的树开始一个新块会有好处或者块的大小已经填满缓冲区，压缩器结束一个块。

压缩器使用链式哈希表来查找重复串，使用一个用3字节系列来计算的哈希函数。压缩时，在任意给定的位置，假设XYZ是接下来的3个输入字节，首先，压缩器检验XYZ的哈希链，如果链为空，压缩器将X作为一个literal字节直接写出，并将XYZ加入到哈希链中，最后将位置往后移动一个字节；如果哈希链不为空，意味着系列XYZ（有可能是其它3个不完全相同的字节有相同的哈希值）最近出现过，压缩器将XYZ哈希链上的所有串和从当前位置开始的真实输入数据系列对比，然后选择一个最长的匹配。

哈希链是单向链接，没有删除操作，压缩算法简单地忽略过时的匹配。为了避免最坏情况，非常长的哈希链会在特定的长度任意截断，这由运行时参数来决定。

为了改善整体的压缩性能，压缩器有选择性地推迟匹配的选择（lazy match）：在一个长度为N的匹配被找到后，压缩器从下个输入字节开始搜索一个更长的匹配。如果找到一个更长的匹配，将先前匹配的长度缩短为1（产生一个单一的literal字节）并且采用更长的匹配；否则，采用原先的匹配，并且将当前位置往后移动N个字节。

运行时参数控制着“lazy match”的过程。如果压缩比是最重要的，不论第一次匹配的长度多长，压缩器都会尝试第二次搜索；在通常的情况下，如果当前匹配足够长了，压缩器就不会去搜索更长的匹配，从而加速压缩的过程；如果速度是最重要的，那么只有当没找到匹配或匹配不是太长时才会将串插入到哈希表中，这样会降低压缩比，但由于需要更少的插入和更少的搜索，所以会节省时间。

## 参考资料 ##

1. [gzip主页](http://www.gzip.org/)
2. [GNU Gzip](http://www.gnu.org/software/gzip/)
3. [wikipedia: Gzip](http://zh.wikipedia.org/wiki/Gzip)
4. [rfc1951: DEFLATE Compressed Data Format Specification version 1.3](http://tools.ietf.org/html/rfc1951)
5. [rfc1952: GZIP file format specification version 4.3](http://tools.ietf.org/html/rfc1952)
6. [gzip格式](http://www.gzip.org/format.txt)
7. [gzip压缩和解压缩算法](http://www.gzip.org/algorithm.txt)
8. [An Explanation of the DEFLATE Algorithm](http://www.gzip.org/deflate.html)

## 后记 ##

文中若有错误或疏漏之处，烦请批评指正。