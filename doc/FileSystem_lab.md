# FileSystem_lab

本次练习会为xv6的文件系统添加大文件和符号链接的功能。

在写代码之前，应该先阅读第八章的文件系统相关内容，并且理解相关的代码。

```shell
  $ git fetch
  $ git checkout fs
  $ make clean
```

## Chapter 8 File system

文件系统的初衷是组织并存储数据。典型的文件系统支持在用户和应用之间共享数据，以及持久化，使得数据在重启后还能获取。

xv6的文件系统提供类Unix的文件、目录，以及路径名。数据被存储在虚拟磁盘上以进行持久化。文件系统需要解决以下的一些挑战：

* 文件系统需要使用在磁盘上的数据结构来表示目录树以及文件，记录存储每个文件内容的块的身份，记录那些磁盘区域是空闲的。
* 文件系统需要支持*crash recovery*。也就是说，在崩溃发生后（比如掉电），文件系统需要在重启后仍然能正确工作。这里的风险是，崩溃可能打断正在执行的一连串更新，使得在磁盘上的数据结构不一致（inconsistent）（比如，一个块被使用，但是被标记为空闲）。
* 不同的进程可能同时使用文件系统，因此文件系统代码必须协调以保持不变量。
* 访问磁盘比访问内存会慢数个数量级，因此文件系统必须在内存中维护缓存用于热数据块

接下来的章节介绍了xv6如何解决以上的问题。

### 8.1 Overview

### Buffer cache layer

### Code: Buffer cache

这里的主要的函数就是`bget`，`brelse`，`bread`，`bwrite`。通过`bget`获得在内存的`struct buf`，读取时，能够直接将内存进行；写入时则进行持久化。比如需要获取同样的数据块，如果已经在内存中则直接能缓存命中。

### Logging layer

在文件系统中最有意思的一个问题是如何崩溃恢复。这问题的出现是因为文件系统的更新会涉及到在磁盘上的多个读取，如果在更新未完成的时候发生崩溃，则可能让磁盘上的文件系统处在不一致的状态。例如，假设在文件截断（truncation，将文件的长度设置为0，并释放其数据块）期间发生崩溃。机遇与磁盘写入的顺序，崩溃可能使得问价系统的inode指向一个被标记为空闲的内容数据块，或者在磁盘上剩下被分配了的但是没有被指向的数据块。

后者是相对良性的，但是一个inode指向一个被释放的块，重启后可能导致严重的问题。在重启后，内核可能分配这个数据块给到另一个文件，使得有两个文件指向相同的数据块。如果xv6支持多用户，则这可能产生安全问题，因为老的文件的持有者的可能能读取到另一个用户的新文件的写入。

xv6通过简单结构的`logging`来解决这以文件系统操作期间崩溃的问题。一个xv6系统调用不会直接写在磁盘上的文件系统数据结构。相反的，系统将对所有的希望对磁盘的写入的描述，存储在磁盘上的log中。一旦系统调用将所有的写入存储在日志中，其写入一个特殊的`commit`记录到磁盘上，以表示这个日志包含一个完整的操作。在这个时间点，该系统调用在复制写入数据到磁盘的文件系统数据结构中。在这个写入完成后，系统调用释放在磁盘上的日志。

如果系统崩溃并重启，文件系统代码在任何其他进程启动前，按照如下方式恢复数据：如果日志被标记为存储有一个完整的操作，则恢复代码复制该写入到磁盘上的文件系统中的正确位置上。如果日志没有被标记为包含完整的操作，恢复代码忽略这个log。恢复代码结束后会释放log。

为什么日志解决了文件系统操作期间崩溃的恢复问题？如果操作在commit之前发生，则日志不会被标记完成，恢复代码会忽略它，磁盘状态为该操作没有发生前的状态。如果崩溃发生在操作被commit之后，则恢复代码会重放所有的操作写，以操作完全没有发生的状态从头到尾执行一次。这种被标记完成的操作相对崩溃来说，是原子的：恢复后，要么所有操作，要么不完成。

### 8.5 Log design

日志存储在一个已知的固定区域，由超级块决定。其包含一个header block，以及随后的连续的更新数据块（“logged blocks”）。header block包含一个sector number数组，用于每个日志中的数据块，日志数据块个数。在header block的计数器要么是0，说明现在没有事务在日志中；要么是非0，说明有事务在日志中，并且日志块个数是`count`个。xv6通过写入header block来完成事务的提交，在将日志中的数据块拷贝到文件系统后，将计数器置零。于是在日志commit之前的崩溃会使得计数器为0，在commit之后的崩溃会使得计数器为非0。

每个系统调用说明写入数据的连续起止地址，并且必须相对崩溃原子的写入。为了让不同的进程能够并发的执行文件系统操作，日志系统能将多个写入累积成一个事务进行提交。于是单个提交可能涉及到多个系统调用的完成。为了避免将系统调用在事务之间切分，日志系统仅在没有文件系统系统调用未完成时commit。

将多个事务一起提交的技术被称为*group commit*。它能降低磁盘操作的数据量，因为其摊销了固定的提交开销到次操作上。组提交技术也使得磁盘系统能更加并发的进行写入，潜在地使得磁盘能在一次旋转中写入所有的日志。Xv6 的虚拟驱动器不支持这样的*batching*，但是xv6的文件系统允许了这样的操作。

Xv6在磁盘上指定固定容量的区域存储日志。总的写入的数据块的数量在一次系统调用中的事务必须能容纳进这个空间中。这导致了两个后果：
* 没有单个系统调用能写入大于这个日志空间容量大小的独立块数量。这对大部分系统调用来说都不是问题，但是有两个系统调用可能写入大量的块：`write`和`unlink`。一个大文件的写可能写入很多数据块以及很多bitmap块，以及inode块。unlink操作对于一个大文件，将产生写入很多的bitmap块和inode块。Xv6的`write`系统调用将大的写，分散为多个小的写，以能容纳进日志中，对于`unlink`并不会造成问题，因为在实践中，xv6文件系统仅使用了一个bitmap block。另一个后果是，有限的日志空间直到确定系统调用大小后，发现能正确容纳于日志的剩余空间中后，才能允许这个系统调用。

### 8.6 Code: logging

在文件系统中典型使用logging的形式如下：

```
begin_op();
...
bp = bread(...);
bp->data[...] = ...;
log_write(bp);
...
end_op();
```

`begin_op, kernel/log.c:127`会等待日志系统直到它不在执行提交，以及等待到日志空间足够容纳这个系统调用需要的写入。`log.outstanding`统计已保留日志空间的系统调用次数。总的保留的空间为`log.outstanding`乘以`MAXOPBLOCKS`。增加`log.outstanding`既能保留空间，也能阻止一个提交在有系统调用的期间提交。这里的代码保守地假设所有的系统调用最多写入`MAXOPBLOCKS`个数据块。

`log_write`的行为类似`bwrite`的代理。其在内存中记录写入的块的扇区号，在磁盘上的一个slot中存储这个日志，将对应的buffer驻留在块缓存中，避免块缓存驱逐它们。这些数据块必须驻留到日志提交之后：提交之后，缓存中的备份修改都已经被持久化了。在日志提交之前，不能将数据写入到对应的地址。其他在同样的事务中的读取操作，必须能看到这样的修改。`log_write`会注意到一个数据块在一个事务中被多次写入，并且在事务中为它们存储在同一个slot。这样的优化通常被称为*absorption*。因为有一种情形是非常常见的，在一个事务中，多个文件inode的多个数据块被多次修改。通过将多次修改吸收为一次，文件系统能节省日志空间，并实现更好的性能（因为最终仅有一个数据块需要被写入磁盘）。

`end_op`首先减少正在执行的系统调用次数的计数器。如果计数器当前为0，则通过`commit()`提交现在的事务。这个过程中有四个阶段。`write_log()`从buffer cache中复制在事务中每个被修改的块，写入到磁盘上的log区域的slot中。`write_head()`写入header block到磁盘上。