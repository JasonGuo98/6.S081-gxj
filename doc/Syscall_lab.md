# Syscall_lab

## before coding

1. XV6 book Chapter 2 and Section 4.3 and 4.4
    1. Section `2.6` start xv6
       1. **boot loader**：当RISC-V的CPU上电时，它初始化其自身，并从一个ROM中读取一个`boot loader`。`boot loader`将xv6的kernel加载到内存，接下来在`machine mode`，CPU将从`kernel/entry.S:7, _entry`运行kernel。此时的虚拟页是没有启动的，虚拟内存和物理内存直接映射。`boot loader`将kernel放到物理内存的`0x80000000`位置。将内核不放到`0x0`的位置是因为在`0x0:0x80000000`之间有很多`I/O`设备。
       2. **_entry**：`_entry`初始化一个栈，之后xv6就可以运行C代码了,这个栈是一个字符串数组。xv6在文件`kernel/start.c`声明一个空间用于初始的栈`stack0`。在`_entry`中的代码为栈的寄存器写入`stack0+hartid*4096`，作为栈的顶部，这是因为在RISC-V中的栈是从上向下生长的。此时内核拥有了一个栈，`_entry`可以运行`kernel/start.c`中的C代码。
          > 这里的可以运行C代码是因为C的函数运行需要栈的支持【个人理解】。
          
          > 在多核CPU中，每个CPU都将运行`entry.S`，为了各个CPU的内存不重叠，其实分配的栈对每个CPU是不同的。
          > `sp = stack0 + (hartid * 4096)`，hartid为CPU ID
       3. **start**：在`start.c`中的函数运行一些配置过程，这种配置仅被允许在`machine mode`运行，之后CPU状态转移为`supervisor mode`。RISC-V提供命令`mret`进入`supervisor mode`。`start`运行`mret`后并不会返回`start`函数，而是通过设置寄存器`mstatus`将之前的特权级到supervisor mode，并将函数的返回地址改成`main()`的地址（修改寄存器`mepc`），在将进入的`supervisor mode`中还避免虚拟地址转换（对page-table 寄存器 `satp`中写入0），并将所有中断和异常委托给supervisor模式。
       4. **clock**：在进入`supervisor mode`之前，`start`还对时钟芯片进行编程以产生时间中断。运行`mret`后，`start`“返回”到`supervisor mode`。由于修改了返回地址，此时的`pc`寄存器修改为了`kernel/main.c`。
       5. **main**：`main()`中初始化了多个设备及子系统，并且创建了第一个进程（通过运行`userinit, kernel.proc.c:226`）。这第一个进程运行少量有RISC-V的汇编编写的代码，并运行xv6中的第一个系统调用。`initcode.S， user/initcode.S:3`将加载`exec`系统调用的编号（`kernel/syscall.h:8`），到寄存器`a7`中，并使用`ecall`命令重新进入系统内核。
          > 注意到`user/initcode.S`中的`exec`调用的第一个参数为`.string /init\0`，这表明`exec`执行的时候，是将二进制文件`/init`用于替换当前的内存状态。
          > `exec`的实现在文件`kernel/sysfile.c`中
       6. **exec**：内核在`syscall, kernel/syscall.c:133`中使用`a7`寄存器来运行指定的系统调用。系统调用表（kernel/syscall:108）将符号`SYS_EXEC`映射到`sys_exec()`。`exec`调用将使用一个新的程序替换当前进程的内存和寄存器，这里将替换为`/init`
       7. **init**：一旦内核完成调用`exec`，操作系统将返回用户态到进程`/init`中。`/user/init.c`创建一个新的命令行`console`设备文件（如果需要），并且将其以文件描述符0,1,2打开。此时命令行启动，系统可以运行其他用户程序。
    2. Sections `4.3` call syscall
         
         在操作系统启动时，`initcode.S`中调用了`exec`将二进制文件`/init`加载并执行。调用`exec`时系统处于用户态，这一节介绍了如何实现在用户态执行系统调用。

         `initcode.S`将执行`exec`的系统调用的参数放到寄存器`a0`和`a1`中，将系统调用号记录在寄存器`a7`中。系统调用号用于在系统调用向量中获取对应的函数指针。`ecall`指令陷入到内核态，并执行`uservec`，`usertrap`，接下来执行`syscall`来执行真正的系统调用。

         `syscall`(kernel/syscall.c:133)从保存的陷入帧（用于从内核返回时恢复上下文）中的a7寄存器中获取系统调用号，用于查询对应的系统调用。据此，内核将执行`sys_exec`函数。

         当`sys_exec`结束后，`syscall`将其返回值保存到`p->trapframe->a0`中。这使得在用户态返回的`exec`的返回值为这里的`a0`，因为RISC-V中的C约定将返回值放在`a0`。如果系统调用出现错误，则会返回负值。
    3. Section `4.4` system call arguments
       在内核实现的系统调用需要用户态的参数。由于在用户态调用时使用了包装（wrapper）函数，其参数位于RISC-V 的C调用能方便地放置的位置，即寄存器中。系统的陷入代码保存用户的寄存器到当前的进程陷入帧（trap frame）中，这样内核能获得他们。`argint`，`argaddr`，`argfd`能从陷入帧中获取第n个参数，分别作为整形，指针，或文件描述符进行解析。他们都调用`argraw`进行解析。
       
         ```c
         int argint(int n, int *ip); //获取第n参数，作为整形，到ip中。

         static uint64$
         argraw(int n)$
         {$                      struct proc *p = myproc();$                                                                                             switch (n) {$
            case 0:$
            return p->trapframe->a0;$
            case 1:$
            return p->trapframe->a1;$
            case 2:$
            return p->trapframe->a2;$
            case 3:$
            return p->trapframe->a3;$
            case 4:$
            return p->trapframe->a4;$
            case 5:$
            return p->trapframe->a5;$
         }$
         panic("argraw");$
         return -1;$
         }
         ```

         一些系统调用使用指针作为参数，内核必须用这些指针来读取或写入用户内存。比如`exec`系统调用，传入一个指针数组，指向用户态的字符串作为参数。这些指针带来了两个挑战：1）用户的进程可能是有bug或恶意的，是无效指针甚至欺骗内核访问内核内存而不是用户内存。2）xv6的用户态页表的mapping和用户的page table mapping是不一样的，所以内核不能直接访问用户提供的地址。

         内核提供了函数用于安全地将用户提供提供的数据发送到内核态。`fetchstr`是一个例子（`kernel/syscall.c:25`）。文件系统调用，比如exec，使用`fetchstr`从用户态获取字符串的文件名。`fetchstr`使用`copyinstr`来执行这一过程。
         ```c
         int$
         fetchstr(uint64 addr, char *buf, int max)$
         {$
         struct proc *p = myproc();$
         int err = copyinstr(p->pagetable, buf, addr, max);$
         if(err < 0)$
            return err;$
         return strlen(buf);$
         }
         ```

         `copyinstr`(`kernel/vm.c:398`)从用户的页表`pagetable`的虚拟地址`srcva`，将最多`max`字节的数据复制到`dst`。由于pagetable不是当前的页表，`copyinstr`使用`walkaddr`（称为`walk`）来查询`srcva`在`pagetable`，产生物理地址`pa0`。内核将每个物理RAM地址映射到对应的虚拟地址，因此`copyinstr`能直接复制字符串字节从`pa0`到`dst`。`walkaddr`(`kernel/vm.c:104`)检查用户提供的虚拟地址空间是用户进程空间的一部分，因此用户程序不能欺骗内核来读取其他的内存。存在一个类似的函数，`copyout`，将数据从内核复制到用户空间。

2. Source code
   1. The user-space code for systems calls is in `user/user.h` and `user/usys.pl`.

      `user/user.h`主要是系统调用的函数声明，以及ulibc的函数声明。
      
      `user/usys.pl`用于生成`user/usys.S`，为各个系统调用在wrapper函数生成实际调用的汇编代码。实际调用时通过将系统调用号传入`a7`寄存器并使用ecall进入内核。此时`系统调用号保存在用户态的栈帧a7中`
   2. The kernel-space code is `kernel/syscall.h`, `kernel/syscall.c`.
      
      `syscall.h`中定义的是各个系统调用号

      `syscall.c`中定义的是内核函数`syscall()`的实现。函数具体实现为：

      ```c
      void
      syscall(void)
      {
         int num;
         struct proc *p = myproc();
         
         num = p->trapframe->a7;
         if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
            p->trapframe->a0 = syscalls[num]();
         } else {
            printf("%d %s: unknown sys call %d\n",
                     p->pid, p->name, num);
            p->trapframe->a0 = -1;
         }
      }
      ```

      即从myproc中获取当前的进程信息，之后从进程的栈帧中取`a7`寄存器，获得系统调用号。之后将系统调用以函数指针数组`syscalls[num]()`的形式调用，并将返回值写入进程的栈帧`a0`寄存器中。如果出现异常，则写入`-1`。

      本文件还定义了内核中系统调用函数的声明，以及从用户态拷贝参数的方法。注意到内核和用户进程使用不同的页表，因此需要从用户的进程信息获取页表后，进一步获取用户态保存的调用参数。用户的系统调用参数都在寄存器中。

      > 为什么用户的调用参数都在寄存器中？
      > 
      > 因为用户调用系统调用，在用户态表现为调用一个函数。调用函数前，系统会先将现在在用的寄存器写入内存的栈，之后使用寄存器进程参数传递。函数内部使用这些寄存器后，也是用寄存器返回函数结果。之后再恢复保存在栈中的函数调用以外的寄存器值。
      


   3. The process-related code is `kernel/proc.h` and `kernel/proc.c`
   
      `kernel/proc.h`声明进程的上下文`struct context`。

      每个时刻，有一进程在某个CPU上运行，因此每个CPU也会记录当前的进程context，和进程信息的指针

      该文件还记录了`trapframe`信息，用于进入内核态后的系统调用

      该文件定义了`struct proc`，是一个进程的状态，上下文，文件描述符，管道（chan），当前目录，陷入栈帧等信息。每个进程还持有一个`spinlock`。

      `kernel/proc.c`

      进程相关的处理函数：进程号、进程初始化、free进程、page table管理、内存空间增加与缩减、fork的实现、获取当前cpu的进程信息、获取当前的cpu号、将当前的进程放弃的子进程交给init进程、init进程启动（1号进程）、exit（一个进程直接退出并不返回，保存在zombie状态，直到父亲进程执行wait）、wait调用

      * `scheduler`
         每个CPU都运行一个scheduler()
         每个CPU在自己设置好后直接运行scheduler()
         Scheduler()从不返回，其直接进入死循环，执行以下的任务：
            * 选择一个进程来执行
            * swtch，到这个选择的进程运行
            * 之后该进程移交控制权，转移到该scheduler()

      * `sched`
         将cpu从用户进程交给schduler
      
      * `yield`
         放弃当前的时间片
      
      * `forkret`
         fork的子进程的首次调度（scheduler()）会被切换到forkret

      * `sleep`
        

      * `wakeup`
        将chan上所有的进程唤醒

      * `kill` 杀死一个给定的进程（仅仅改变状态）

      * `either_copyout`
        将数据拷贝到用户空间或内核空间

      * `either_copyin`
        将数据从用户空间或内核空间拷贝

      * `procdump`
        打印进程信息列表到控制台，用于debug，当用户 输入 ctrl+p时启动
      

## do lab

### system call tracing

为系统添加用户态程序trace，能够跟踪进程和子进程执行调用了哪些被跟踪的系统调用。

#### 实现

1. 添加`$U/_trace`到makefile的`UPROGS`
   1. `user/trace.c`是一个用户态程序，调用了`trace()`函数，是一个系统调用
2. `trace()`函数在用户态还不存在，直接make qeum会失败，需要在相关文件中添加其函数定义：
   1. `int trace(int);` 添加到`user/user.h`，这里声明函数的C定义，调用这里的函数后，编译器会找到真正的执行函数进行执行。
   2. `entry("trace");` 添加到`user/usys.pl`， 这个文件会被make 调用，生成`user/usys.S`，是真正的系统调用入口（执行risc-v的ecall指令），也是在`user.h`中定义的函数的执行代码，以汇编形式存在
   3. `#define SYS_trace  22` 添加到`kernel/syscall.h`，因为在`usus.S`中需要符号`SYS_trace`的值
   
   此时可以make 成功，但是执行`trace 32 grep hello README`仍然会失败，因为没有具体的内核系统调用用于执行：

   ``` shell
   $ trace 32 grep hello README
   5 trace: unknown sys call 22
   trace: trace failed
   ```
   个人很好奇的是，这个syscall的错误是谁爆出来的，答案是`kernel/syscall.c`中的syscall()函数爆出来的，它会检查系统调用是否在内核中有实现用于执行。

   第二个点是，这里的trace的系统调用没有实现，但是仍然能够正常编译，是为什么？
   因为系统调用是通过函数数组实现的，因此调用的不是通过真正的符号进行调用，能够发现使用的符号没有定义，而是通过调用号进行调用的，不能被编译器检查到。
3. 在内核中实现`sys_trace`系统调用
   1. 在`kernel/sysproc.c`中添加系统调用函数:
      ```c
      // my implementation of trace system call function$
      uint64$
      sys_trace(void)$
      {$
         int mask;$
         if(argint(0, &mask) < 0)$
            return -1;$
         do smt; // TODO $
         return;
      }
      ```
   2. 修改进程数据结构记录mask
   
      由于进程可能在后台执行，还可能产生子进程，需要在进程数据结构中记录mask信息，其实上面的调用就是修改进程的这个mask数据，在执行调用的时候不断查看这个数据段是否置为一，以选择是否打印相关信息。初始化时，mask的值应该是0。

      修改`kernel/proc.h`，向`struct proc{}`中添加字段:
      ```c
      uint64 trace_mask;           // trace syscall mask
      ```
      因此`sys_trace`中的`do smt;`改成修改该字段：
      
      ```c
      myproc()->trace_mask = mask;
      ```
      这里的疑问是需不需要锁，应该是不需要，因为在内核中不会被打断。

      另外初始化时，mask的值应该是0。`init`启动后，所有的进程都是它的fork（通过shell），因此我们需要让第一个进程的mask值是0，并且通过fork继承。

      所有的进程表都是全局变量，C语言保证了初始化第一个进程的默认值是0
   3. 修改`fork()`

      `kernel/proc.c`中的`fork()`调用能创造一个复制父进程的子进程，在这里复制父亲的mask

      为什么fork会返回两次，在子进程中返回0，父进程返回pid，这是因为实现的时候
      ```c
      // Cause fork to return 0 in the child.
      np->trapframe->a0 = 0;

      return pid;// parent return 
      ```

      代码中还有很多有意思的点，解答为什么系统的状态是如同教科书的表述，修改为添加复制`trace_mask`

      ```c
      int$
      fork(void)$
      {$
      int i, pid;$
      struct proc *np;$
      struct proc *p = myproc();$
      $
      // Allocate process.$
      if((np = allocproc()) == 0){$//这里是从进程表中获取一个新的进程结构，进程表在init启动前就已经定义在内核的全局空间中了，是一个全局变量，由于C初始化全局变量为0，因此状态也是0（UNUSED），这里持有了np的锁
         return -1;$
      }$
      $
      // Copy user memory from parent to child.$
      if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){$
         freeproc(np);$
         release(&np->lock);$
         return -1;$
      }$
      np->sz = p->sz;$// 这里的sz是Size of process memory (bytes) 在用户空间的内存大小

      np->trace_mask = p->trace_mask;// 添加mask复制
      $
      // copy saved user registers.$
      *(np->trapframe) = *(p->trapframe);$
      $
      // Cause fork to return 0 in the child.$
      np->trapframe->a0 = 0;$
      $
      // increment reference counts on open file descriptors.$
      for(i = 0; i < NOFILE; i++)$
         if(p->ofile[i])$
            np->ofile[i] = filedup(p->ofile[i]);$
      np->cwd = idup(p->cwd);$// 从这里可以看到，每个进程都有自己的inode 指针作为当前的工作目录
      $
      safestrcpy(np->name, p->name, sizeof(p->name));$
      $
      pid = np->pid;$
      $
      release(&np->lock);$// 这里可能有疑问，为什么只有释放锁，没有获取锁，这是因为在allocproc()中已经持有锁，所以修改np的相关信息要在这一行之前
      // 为什么不能在锁内部再获取wait_lock，可能是避免循环等待问题？
      $
      acquire(&wait_lock);$
      np->parent = p;$
      release(&wait_lock);$
      $
      acquire(&np->lock);$
      np->state = RUNNABLE;$
      release(&np->lock);$
      $
      return pid;$
      }
      ```
4. 修改`syscall()`函数用于输出，并添加系统调用名称列表用于打印
   1. 添加`extern uint64 sys_trace(void);`和`[SYS_trace]   sys_trace,`
      系统调用表长这样
      ```c
      static uint64 (*syscalls[])(void) = {$
      [SYS_fork]    sys_fork,$
      [SYS_exit]    sys_exit,$
      [SYS_wait]    sys_wait,$
      [SYS_pipe]    sys_pipe,$
      [SYS_read]    sys_read,$
      [SYS_kill]    sys_kill,$
      [SYS_exec]    sys_exec,$
      [SYS_fstat]   sys_fstat,$
      [SYS_chdir]   sys_chdir,$
      [SYS_dup]     sys_dup,$
      [SYS_getpid]  sys_getpid,$
      [SYS_sbrk]    sys_sbrk,$
      [SYS_sleep]   sys_sleep,$
      [SYS_uptime]  sys_uptime,$
      [SYS_open]    sys_open,$
      [SYS_write]   sys_write,$
      [SYS_mknod]   sys_mknod,$
      [SYS_unlink]  sys_unlink,$
      [SYS_link]    sys_link,$
      [SYS_mkdir]   sys_mkdir,$
      [SYS_close]   sys_close,$
      [SYS_trace]   sys_trace,$
      };
      ```
      这是因为c语言中允许初始化特定下标的数组

   2. 添加索引用于打印调用名

      ```c
      static char * syscalls_name[] = {$
      [SYS_fork]    "fork",$
      [SYS_exit]    "exit",$
      [SYS_wait]    "wait",$
      [SYS_pipe]    "pipe",$
      [SYS_read]    "read",$
      [SYS_kill]    "kill",$
      [SYS_exec]    "exec",$
      [SYS_fstat]   "fstat",$
      [SYS_chdir]   "chdir",$
      [SYS_dup]     "dup",$
      [SYS_getpid]  "getpid",$
      [SYS_sbrk]    "sbrk",$
      [SYS_sleep]   "sleep",$
      [SYS_uptime]  "uptime",$
      [SYS_open]    "open",$
      [SYS_write]   "write",$
      [SYS_mknod]   "mknod",$
      [SYS_unlink]  "unlink",$
      [SYS_link]    "link",$
      [SYS_mkdir]   "mkdir",$
      [SYS_close]   "close",$
      [SYS_trace]   "trace",$
      };
      ```

   3. 添加打印代码到`syscall()`

      ```c
      void$
      syscall(void)$
      {$
      int num;$
      struct proc *p = myproc();$
      $
      num = p->trapframe->a7;$
      if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {$
         p->trapframe->a0 = syscalls[num]();$
         if(((p->trace_mask) >> num) & 1){$
            printf("%d: syscall %s -> %d\n", p->pid, syscalls_name[num], p->trapframe->a0);$
         }$
      } else {$
         printf("%d %s: unknown sys call %d\n",$
                  p->pid, p->name, num);$
         p->trapframe->a0 = -1;$
      }$
      }
      ```
      到此添加成功系统调用，注意打印的格式要和题目一致，否则测试不通过

#### 测试

1. `make grade`测试

   ```shell
   make[1]: Leaving directory '/home/gxj/xv6-labs-2021'
   == Test trace 32 grep ==
   $ make qemu-gdb
   trace 32 grep: OK (2.3s)
      (Old xv6.out.trace_32_grep failure log removed)
   == Test trace all grep ==
   $ make qemu-gdb
   trace all grep: OK (0.4s)
      (Old xv6.out.trace_all_grep failure log removed)
   == Test trace nothing ==
   $ make qemu-gdb
   trace nothing: OK (0.7s)
   == Test trace children ==
   $ make qemu-gdb
   trace children: OK (10.0s)
      (Old xv6.out.trace_children failure log removed)
   ```
   表明通过测试

## Sysinfo

添加一个系统调用`sysinfo()`用于操作数据结构：

```c
struct sysinfo {
  uint64 freemem;   // amount of free memory (bytes)
  uint64 nproc;     // number of process
};
```

该系统调用获取一个指向`struct sysinfo`的指针，并将系统状态写入其中。lab提供了一个`sysinfotest`用户程序来测试

#### 实现
1. Add $U/_sysinfotest to UPROGS in Makefile
2. 实现用户态sysinfo()调用接口，否则make失败
   1. `int sysinfo(int);` 添加到`user/user.h`，这里声明函数的C定义，调用这里的函数后，编译器会寻找真正的执行函数进行执行。

      ```c
      struct sysinfo;//添加结构声明，实现在内核中
      int sysinfo(struct sysinfo *);
      ```



   2. `entry("sysinfo");` 添加到`user/usys.pl`， 这个文件会被make 调用，生成`user/usys.S`，是真正的系统调用入口（执行risc-v的ecall指令），也是在`user.h`中定义的函数的执行代码，以汇编形式存在
   3. `#define SYS_sysinfo  22` 添加到`kernel/syscall.h`，因为在`usus.S`中需要符号`SYS_sysinfo`的值

   此时可以成功编译`make qemu`，但是执行`sysinfotest`会因为没有实现系统调用而失败
   ```shell
   $ ./sysinfotest
   sysinfotest: start
   3 sysinfotest: unknown sys call 23
   FAIL: sysinfo failed
   ```

3. 实现内核调用

   提示中说到，需要将内核中的一个`sysinfo`结构拷贝到用户空间中，因此需要做三件事
   1. 声明一个内核空间中的`sysinfo结构` : 
      1. sysinfo结构声明在`kernel/sysinfo.h`中，我们在sysproc中引用该头文件，并在函数中定义一个sysinfo结构

   2. 检查用户提供的地址是否安全（是不是用户自己的）
      1. 使用`argaddr()`获取目标地址
   3. 执行拷贝
      1. 使用`copyout()`函数
      2. 注意在`sysproc.c`中添加头文件`sysinfo.h`，否则sizeof执行失败


      参考sys_fstat() (`kernel/sysfile.c`)实现到`sysproc.c`中：
      ```c
         // my implementation of sysinfo system call function$
         $
         uint64$
         sys_sysinfo(void)$
         {$
            uint64 addr;$
            if(argaddr(0, &addr) < 0 )$
               return -1;$
            struct sysinfo info;

            if(copyout(myproc()->pagetable, addr, (char *)&info, sizeof(info)) < 0)$
               return -1;$
            return 0;$
         $
         }
      ```
      注意需要和之前添加系统调用类似添加到系统调用表中，并且在syscall.c中extern调用函数

4. 内核变量`info`修改
   1. To collect the amount of free memory, add a function to `kernel/kalloc.c`
      1. 添加获取freelist 中free页面大小的函数
         ```c
         // get free memory size (Byte)$
         uint64$
         kfreememsize(void)$
         {$
            struct run *r;$
            uint64 free_page_n = 0;$
            $
            acquire(&kmem.lock);$
            r = kmem.freelist; // one page is 4096 Byte$
            while(r)$
            {$
               r = r->next;$
               free_page_n++;$
            }$
            release(&kmem.lock);$
            return 4096*free_page_n;$
         }
         ```
      2. 将函数添加到`defs.h`中，用于执行
         ```c
         uint64          kfreememsize(void);
         ```
   2. To collect the number of processes, add a function to kernel/proc.c
      1. 添加获取使用proc数量的函数
         ```c
         // add function to get number of non-[UNUSED] proc$
         uint64$
         procnum(void)$
         {$
         struct proc *p;$
         uint64 cnt = 0;$
         $
         for(p = proc; p < &proc[NPROC]; p++) {$
            acquire(&p->lock);$
            if(p->state != UNUSED) {$
               cnt++;$
            }$
            release(&p->lock);$
         }$
         return cnt;$
         }
         ```
      2. 添加函数到`kernel/defs.h`

         ```c
         uint64 procnum(void);
         ```

#### 测试

```shell
$make grade

== Test sysinfotest ==
$ make qemu-gdb
sysinfotest: OK (1.9s)
```
   

   

