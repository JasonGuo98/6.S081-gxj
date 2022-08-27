# Lab: Copy-on-Write Fork for xv6

虚拟内存提供一定程度的间接性：内核可以通过将 PTE 标记为无效或只读来拦截内存引用，使页失效发生，并且可以通过修改PTEs来改变地址的含义。有一种说法是，计算机系统中的很多问题都可以通过一个新的间接层来解决。lazy allocation lab提供了一个样例。这个lab探索了另一个案例：Copy-on-Write fork。

首先切换分支：

```
$ git fetch
$ git checkout cow
$ make clean
```

## The problem

在xv6中，`fork()`系统调用会复制所有父亲进程的用户态内存到子进程中。如果父进程很大，复制可能会花费很长的时间。更糟糕的时，这一工作通常非常浪费：例如，一个fork()后执行exec()调用的子进程，会丢失复制的所有父进程的内存，可能根本不会用到大部分的父进程中的内存复制。另一方面，如果父子进程都使用一个页面地址，并且一个或两个都写这一页地址，那么确实需要一个复制操作。

## The solution

Cow fork()的目的是推迟为子进程分配并复制物理内存页到这些复制真的被需要时（如果有的话）。

Cow fork()仅仅为子进程创建页表，将用户态的PTE指向父进程的物理页。COW fork()将父子进程的用户态PTE都设置为不可写。当任一进程尝试写COW页时，CPU会产生一个页错误。内核页错误处理程序会探测到它的出现，为出现页错误的进程分配物理页，复制原本的物理页到新的页中，并在失效的进程中修改对应的PTE指向这个新分配的物理页，将PTE设置为可写。当page fault handler返回时，用户程序能顺利写入这一复制出来的页。

COW fork() 使实现用户内存的物理页面的释放变得有点棘手。一个给出的物理页可能被多个进程的页表引用，并且只能在最后一个引用失效时释放。

## Implement copy-on write

### 任务说明

> 任务是在xv6内核中实现Copy-on-write fork。如果通过`cowtest`和`usertests`，则修改后的内核通过测试。

为了帮助测试实现的正确性，lab提供了一个xv6用户态测试程序`cowtest`。`cowtest`会运行多种测试，如果没有修改内核，第一个测试就会失败。输出如下：

```
$ cowtest
simple: fork() failed
$
```

这一"simple" test 分配大半的可用物理内存，接下来执行`fork()s`。这样会失败，因为没有可用的物理内存了。

当完整实现后，内核能够通过所有的`cowtest`和`usertests`测试，输出如下：

```
$ cowtest
simple: ok
simple: ok
three: zombie!
ok
three: zombie!
ok
three: zombie!
ok
file: ok
ALL COW TESTS PASSED
$ usertests
...
ALL TESTS PASSED
$
```

### 计划和提示

如下有一份合理的计划：

1. 修改`uvmcopy()`用于映射父进程的物理页到子进程，而不是分配一个新的页。在父子进程中都清空`PTE_W`。
2. 修改`usertrap()`用于识别page fault。当一个page-fault发生在COW的页时，由`kalloc()`分配一个新的页，复制旧的页到新的页中，并将新页的PTE设置`PTE_W`。
3. 确保每个物理页在最后一个PTE引用清空后被释放。一个好的实现方法是为每个物理页维护一个引用计数器。当第一次由`kalloc()`分配时将引用设置为1。当`fork()`时将引用计数器加1，在每次including释放页时将引用计数器减一。`kfree()`应该仅在页的引用计数为0时释放。可以维护一个固定大小的整型数组，但需要给出一种机制确定如何在数组中索引并确定这一个数组的大小。例如，需要根据物理内存除以4096的值来索引，并让这个数组的元素个数等于在`kinit(), kalloc.c`分配的free list中最大物理地址值（除以4096）。

一些提示：

* lazy page allocation lab可能让你熟悉大量xv6与cow相关的代码。但是，你不应该基于lazy allocation的解决方案，而是从全新的xv6副本开始这一lab。
* 为每个PTE记录是否是COW页会有帮助。你可以使用RISC-V的PTE中的RSW(reserved for software)位来实现这一功能
* `usertests`会探索`cowtest`没有测试的其他场景，不要忘记将两个测试都通过
* 一些与页表flag相关的宏在`kernel/riscv.h`。
* 如果COW页错误发生，但是仍然没有可用内存，这一进程应该被杀死。(不是在fork时kill，而是在page fault时)

### do lab

#### `uvmcopy`发生了什么
首先我们要确定在`fork()`时发生了什么。

```
// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int
fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if((np = allocproc()) == 0){
    return -1;
  }

  // Copy user memory from parent to child.
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++)
    if(p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;
  release(&np->lock);

  return pid;
}
```

可以看到，在fork中，有关父子进程页表复制的函数是`uvmcopy()`。`uvmcopy`只在这里调用，因此仅仅需要修改`uvmcopy()`，fork中的其他部分不需要修改。

```
$ find ./kernel | xargs grep uvmcopy
grep: ./kernel: Is a directory
./kernel/defs.h:int             uvmcopy(pagetable_t, pagetable_t, uint64);
./kernel/proc.c:  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
./kernel/vm.c:uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
./kernel/vm.c:      panic("uvmcopy: pte should exist");
./kernel/vm.c:      panic("uvmcopy: page not present");
```

`uvmcopy()`函数的实现如下：

```c
// Given a parent process's page table, copy
// its memory into a child's page table.
// Copies both the page table and the
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    flags = PTE_FLAGS(*pte);
    if((mem = kalloc()) == 0)
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
      kfree(mem);
      goto err;
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
  return -1;
}

```

其实这里蛮奇怪的点是，用户态进程的内存都是连续的：
```
for(i = 0; i < sz; i += PGSIZE){
    f((pte = walk(old, i, 0)) == 0)
    {
        ;
    }
}
```

`i`指向的是用户态的虚拟地址，但是虚拟地址空间刚好`p->sz`个。这是因为xv6的进程地址空间是连续分配，且从0开始的。

> 那么用户的trampoline和trapframe呢？


![](imgs/user_address_mapping.png)

这个可以在`proc_pagetable()`和`growproc()`中找到答案，`TRAMPOLINE`和`TRAPFRAME`都是在这里映射的，但是`p->sz`并不改变。

同时`growproc()`用于用户进程内存的扩缩容，其都是以页表为连续，并且直接在最高地址加减进行操作的。

xv6的用户态地址是从0开始，以`p->sz`结束，和`linux`有些不同。

![](imgs/linux_proc_mem_layout.png)

#### 修改`uvmcopy`

我们需要让所有的page在两个页表中的`PTE_W`都为0；设置`RSW, reserved for software`位为1，用于确保发生page fault时，只有COW page被复制。

![](imgs/pte_field.png)

RSW 的值为`3L << 8`，因此在`riscv.h`中添加这个宏

```
#define PTE_COW (1L << 8) // 1 -> is cow page
```

```c
// Given a parent process's page table, copy
// its memory into a child's page table.
// Copies both the page table and the
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);

    if(0 == ((*pte) & PTE_COW)) // not a cow page before
        pagerefcnt[PA2IDX(pa)]++;

    *pte &= (-1L)^PTE_W; // set PTE_W to 0 in parent
    *pte |= PTE_COW; // set PTE_COW to 1 in parent

    flags = PTE_FLAGS(*pte);

    if(mappages(new, i, PGSIZE, (uint64)pa, flags) != 0){ //increase refcnt if cow page
      goto err;
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1); // decrease refcnt if cow page
  return -1;
}
```


我这里的实现做了一些选择：

* 在`uvmcopy`中进行父子进程页表的映射，仅在成功映射一个页时增加引用计数
* 增加引用计数的实现是在`mappages()`中，仅仅在页表复制时进行复制，也就是PTE_COW为1时复制。
* 注意我们对内核的物理页不进行引用计数，比如`walk`分配的页表。
* 当出现错误时，使用`uvmunmap`进行页释放，并且减去有`PTE_COW`的引用计数
* 引用计数器使用物理内存进行索引。计数器数组保存在全局变量中，定义在`vm.c`中，并且在`proc.h`中引用。注意到引用计数最大值为`NPROC = 64`，所以使用uint64是完全没有问题的。
* 数组的大小需要根据`kinit()`设计

    已知内核和用户态内存是从`KERNBASE`到`PHYSTOP`，所以我们可以设置的数组大小为`(PHYSTOP-KERNBASE)>>PGSHIFT`

    ```
    // in vm.c
    uint64 pagerefcnt[(PHYSTOP-KERNBASE)>>PGSHIFT];

    //in kalloc.c

    extern uint64 pagerefcnt[(PHYSTOP-KERNBASE)>>PGSHIFT];

    //in riscv.h
    #define PA2IDX(pa) ((((uint64)pa)-KERNBASE) >> PGSHIFT)
    ```

    由于是全局变量，因此值直接为全0。但是在每次`kalloc()`分配到的时候还需要设置为1。

    这里我们还定义了`PA2IDX`，用于将内存映射到数组下标。

* 我们这里没有在分配失败时，为父进程恢复PTE。这是父进程的PTE有可能本身就是一个COW页。这里我选择用`page fault`进行处理，当`page fault`发现一个引用计数为1的COW页时，会恢复`PTE_W`并清空`PTE_COW`。

#### 修改`uvmunmap()`和`mappages()`

`uvmunmap()`需要减少引用计数，并在引用计数为0时释放页。

注意到函数中有一个`do_free`。在COW之前，这个值确实表示是否释放，但是在COW之后，这个参数表示引用计数为0时是否释放该页。

```
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
```


内核中有多处使用到了`uvunmap`：

```
$ find ./kernel | xargs grep uvmunmap
grep: ./kernel: Is a directory
./kernel/defs.h:void            uvmunmap(pagetable_t, uint64, uint64, int);
./kernel/proc.c:    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
./kernel/proc.c:  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
./kernel/proc.c:  uvmunmap(pagetable, TRAPFRAME, 1, 0);
./kernel/vm.c:uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
./kernel/vm.c:    panic("uvmunmap: not aligned");
./kernel/vm.c:      panic("uvmunmap: walk");
./kernel/vm.c:      panic("uvmunmap: not mapped");
./kernel/vm.c:      panic("uvmunmap: not a leaf");
./kernel/vm.c:    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
./kernel/vm.c:    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
./kernel/vm.c:  uvmunmap(new, 0, i / PGSIZE, 1);
```

修改`uvmunmap()`如下：

```
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free) {
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
      panic("uvmunmap: not a leaf");

    uint64 pa = PTE2PA(*pte);

    if((*pte) & PTE_COW)
      pagerefcnt[PA2IDX(pa)]--;
    if(do_free && pagerefcnt[PA2IDX(pa)] == 0){
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
```

`mappages()`需要增加引用计数，修改如下：

```
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
  last = PGROUNDDOWN(va + size - 1);
  for(;;){
    if((pte = walk(pagetable, a, 1)) == 0)
      return -1;
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;

    if(perm & PTE_COW)
        pagerefcnt[PA2IDX(pa)]++;

    if(a == last)
      break;
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
}
```

> 注意到有的设备的映射是小于`KERNBASE`的，因此需要跳过这样的物理地址。

#### 修改`kalloc()`和`kfree()`

需要确保分配和释放的内存都是没有引用的。

```
// kfree()

if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  if(pagerefcnt[PA2IDX(pa)] != 0)
      panic("kfree cow ref cnt not zero!");

// kalloc()

if(r){
    memset((char*)r, 5, PGSIZE); // fill with junk
    if(pagerefcnt[PA2IDX(r)] != 0)
        panic("alloc phy mem ref cnt not zero!");
  }
```

#### 修改`usertrap()`

这一修改是为了捕获page fault。RISC-V的cpu能分辨三种page fault：
1. load 指令导致的（load 时无法翻译对应的虚拟地址）
2. store 指令导致的
3. instruction（pc指向的代码无法翻译）

之后`scause`寄存器会指示发生了何种page fault，并由`stval`寄存器包含无法翻译的地址。我们需要处理的是`store`指令导致的page fault。

下面贴一份`RISC-V` 部分supervisor寄存器的功能的[文档](https://five-embeddev.com/riscv-isa-manual/latest/supervisor.html#sec:scause)：

* Supervisor Scratch Register (sscratch)
    
    sscratch是一个SXLEN-bit 读写寄存器，在supervisor下使用。通常，在hart执行user代码时，sscratch是用于保存一个指向本地 supervisor上下文的地址。在trap处理开始时，sscratch与user 寄存器交换，提供一个初始的working寄存器。

* Supervisor Exception Program Counter (sepc)

    管理者异常程序计数器
    sepc是一个SXLEN-bit 读写寄存器。格式如下：

    sepc[0]总是为0。在只支持IALIGN=32的实现中，两个低位(sepc[1:0])总是0。

    如果实现允许IALIGN为16或32(例如，通过更改CSR misa)，那么，每当IALIGN=32时，位sepc[1]在读取时被屏蔽，使其看起来为0。这种屏蔽也发生在SRET指令隐式读取时。尽管被屏蔽，当IALIGN=32时，sepc[1]仍然是可写的。

    sepc是一个WARL寄存器，必须能够保存所有有效的虚拟地址。它不需要能够保存所有可能的无效地址。在编写sepc之前，实现可能会将一个无效地址转换成其他一些sepc可以保存的无效地址。

    当一个trap陷入s模式时，sepc被写入被中断或遇到异常的指令的虚拟地址。否则，sepc永远不会写。

* Supervisor Cause Register (scause)

    scause是一个SXLEN-bit 读写寄存器，格式如下：

    当一个trap进入s模式时，cause会用一个代码来表示导致trap的事件。
    如果trap是由中断引起的，则在cause寄存器中设置Interrupt位。Exception Code字段包含了最后一次发生异常和中断的编码。

    ![scause](./imgs/scause.png)

    ```
    Interrupt	Exception Code	Description	
    1	0	Reserved	
    1	1	Supervisor software interrupt	
    1	2–4	Reserved	
    1	5	Supervisor timer interrupt	
    1	6–8	Reserved	
    1	9	Supervisor external interrupt	
    1	10–15	Reserved	
    1	≥16	Designated for platform use	
    0	0	Instruction address misaligned	
    0	1	Instruction access fault	
    0	2	Illegal instruction	
    0	3	Breakpoint	
    0	4	Load address misaligned	
    0	5	Load access fault	
    0	6	Store/AMO address misaligned	
    0	7	Store/AMO access fault	
    0	8	Environment call from U-mode	
    0	9	Environment call from S-mode	
    0	10–11	Reserved	
    0	12	Instruction page fault	
    0	13	Load page fault	
    0	14	Reserved	
    0	15	Store/AMO page fault	
    0	16–23	Reserved	
    0	24–31	Designated for custom use	
    0	32–47	Reserved	
    0	48–63	Designated for custom use	
    0	≥64	Reserved
    ```
    
* Supervisor Trap Value (stval) Register

    stval是一个SXLEN-bit 读写寄存器，格式如下：

    ![stval](./imgs/stval.png)

    当一个trap进入s-mode时，stval将保存异常特别的信息，以供软件处理。硬件平台将指令哪些异常信息设置到stval，哪些设置stval为0。在发生breakpoint（断点），address-misaligned(地址不对齐)，access-fault(访问错误)，page-fault(缺页异常)时，stval被写入包含错误的虚拟地址。


> 所以我们需要判定的类型是`scause == 15`, Store/AMO page fault
> 
> 以及获取`stval`寄存器的值

```
} else if(r_scause() == 15){
    // Store/AMO page fault
    uint64 accessaddr = r_stval();

    if(cowcopy(p->pagetable, accessaddr) < 0)
    {
        printf("alloc COW page fault pid=%d\n", p->pid);
        p->killed = 1;
    }
  }
```

这里我们需要实现`cowcopy()`函数：

```
// in vm.c

// alloc a page, and copy a cow page to it
int cowcopy(pagetable_t pagetable, uint64 va)
{
    pte_t * pte = walk(pagetable, va, 0);
    uint64 pa = PTE2PA(*pte);
    uint flags;


    if(0 == ((*pte) & PTE_COW))
    {
        panic("not a cow page!");
    }
    
    if(pagerefcnt[PA2IDX(pa)] == 1)
    {
        //修改PTE_W和PTE_COW
        *pte |= PTE_W;
        *pte ^= PTE_COW;
        pagerefcnt[PA2IDX(pa)] = 0;
    }
    else if(pagerefcnt[PA2IDX(pa)] > 1)
    {
        uint64 mem = (uint64) kalloc();
        if(!mem)
            return -1;

        flags = PTE_FLAGS(*pte);
        flags |= PTE_W;
        flags ^= PTE_COW;
        
        if(copyin(pagetable, (char*)mem, PGROUNDDOWN(va), PGSIZE) < 0)
            return -1;
        
        uvmunmap(pagetable, PGROUNDDOWN(va), 1, 1);

        mappages(pagetable, PGROUNDDOWN(va), PGSIZE, mem, flags);
    }
    else 
    {
        panic("wrong cow addr!");
    }
    return 0;
}

// in defs.h

int             cowcopy(pagetable_t, uint64);
```

#### 第一次测试


```
$ cowtest
simple: ok
simple: ok
three: ok
three: ok
three: ok
file: eererorrr:r orreroard::  rf eaaridela def daf
iailleded
```

其实第一本版实现bug非常多，建议使用`gdb`调试。



#### `copyout`

为什么最后这个测试没有通过，是因为`copyout`没有实现。因为最后一个测试会使用`pipe()`进行读写，会使用`copyout`进行复制内存。

这里如果不实现，会崩溃的原因是：如果进程使用`pipe()`通信，但是用户态的buffer是cow页，此时使用`copyout`会让父子进程的buffer都被写，然而实际上只能让一个进程的写入。所以我们需要在`copyout`时，如果遇到cow页，进行页错误一样的处理。

```
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    va0 = PGROUNDDOWN(dstva);
    pa0 = walkaddr(pagetable, va0);
    pte_t * pte = walk(pagetable, va0, 0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    if(n > len)
      n = len;
    if(((*pte) & PTE_COW)&&(0 == ((*pte)&PTE_W)))
    {
      if(cowcopy(pagetable, va0) < 0)
          return -1;
    }

    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
        return -1;
    memmove((void *)(pa0 + (dstva - va0)), src, n);

    len -= n;
    src += n;
    dstva = va0 + PGSIZE;
  }
  return 0;
}
```


#### 测试2

```
$ cowtest
simple: ok
simple: ok
three: ok
three: ok
three: ok
file: ok
ALL COW TESTS PASSED

$ usertests
usertests starting
test MAXVAplus: panic: walk
QEMU: Terminated
```

但是`usertests`还不能通过。我们之前写程序，都只要保证在正常情况下的正确性，但是内核需要保证在正常以及异常情况下，都能正确处理。我处理的两个错误都是由于walk函数使用了大于`VMAX`的虚拟地址

1. 程序读写的内存不合法也会造成page fault。需要判断。
2. copyout中使用了`walk`函数，需要在`va`错误就退出，而不进入`walk`。


修改后：

```
// in uvmcopy
if(va >= MAXVA) //add va judge
    return -1;
pte_t * pte = walk(pagetable, va, 0);
if(pte == 0) //add pte judge, va may not belone to this process
    return -1;

// in copyout
va0 = PGROUNDDOWN(dstva);
pa0 = walkaddr(pagetable, va0);
 //pte_t * pte = walk(pagetable, va0, 0); //delete
if(pa0 == 0)
    return -1;
pte_t * pte = walk(pagetable, va0, 0); //add

```

#### 加锁

还有一个测试没有通过是`usertest`的`pgbug`，会在CPU数量为4时崩溃，但是在CPU为1的时候没有问题。

```
test pgbug: panic: alloc phy mem ref cnt not zero!
```

一个可能的问题是我们没有对`refcnt`进行临界区的保护。

```
//in vm.c
#include "spinlock.h"
struct spinlock pgreflock;

// in kvmmake()

initlock(&pgreflock, "pgf");

// 之后在所有pagerefcnt的地方进行锁`acquire`和`release`
```

之后所有`usertests`能通过，但是`cowtest`又过不了了。非常奇怪。这是因为我们的锁存在重复，就是在同一个cpu上锁后，再次在同一cpu请求锁。


加锁方法
```
// mappages()
if(perm & PTE_COW)
{
    acquire(&pgreflock);
    pagerefcnt[PA2IDX(pa)]++;
    release(&pgreflock);
}

//uvmunmap()
acquire(&pgreflock);
if((*pte) & PTE_COW)
{
    pagerefcnt[PA2IDX(pa)]--;
}
if(do_free && pagerefcnt[PA2IDX(pa)] == 0){
    uint64 pa = PTE2PA(*pte);
    kfree((void*)pa);
}
release(&pgreflock);

//uvmcopy
if(0 == ((*pte) & PTE_COW)) // not a cow page before$
{
    acquire(pgreflock);
    pagerefcnt[PA2IDX(pa)]++;
    release(&pgreflock);
}

//cowcopy()

acquire(&pgreflock);
if(pagerefcnt[PA2IDX(pa)] == 1)
{
    //修改PTE_W和PTE_COW
    *pte |= PTE_W;
    *pte ^= PTE_COW;
    pagerefcnt[PA2IDX(pa)] = 0; 
    release(&pgreflock);
}
else if(pagerefcnt[PA2IDX(pa)] > 1)
{
    release(&pgreflock);
    uint64 mem = (uint64) kalloc();
    if(!mem)
    {
        return -1;
    }
    flags = PTE_FLAGS(*pte);
    flags |= PTE_W;
    flags ^= PTE_COW;
    
    if(copyin(pagetable, (char*)mem, PGROUNDDOWN(va), PGSIZE) < 0)
    {
        return -1;
    }
    uvmunmap(pagetable, PGROUNDDOWN(va), 1, 1);

    mappages(pagetable, PGROUNDDOWN(va), PGSIZE, mem, flags);
}
else
{
    panic("wrong cow addr!");
}
```


之后能够通过所有两次测试，添加time.txt。使用`make grade`获得所有得分。



```
$ make qemu-gdb
(7.5s)
== Test   simple ==
  simple: OK
== Test   three ==
  three: OK
== Test   file ==
  file: OK
== Test usertests ==
$ make qemu-gdb

(110.9s)
== Test   usertests: copyin ==
  usertests: copyin: OK
== Test   usertests: copyout ==
  usertests: copyout: OK
== Test   usertests: all tests ==
  usertests: all tests: OK
== Test time ==
time: OK
Score: 110/110
```

