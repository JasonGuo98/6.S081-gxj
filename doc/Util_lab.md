# Util_lab

## sleep
在xv6中实现`sleep`命令

   一些建议：
   1. Before you start coding, read Chapter 1 of the xv6 book.
   2. Look at some of the other programs in user/ (e.g., user/echo.c, user/grep.c, and user/rm.c) to see how you can obtain the command-line arguments passed to a program.
   3. If the user forgets to pass an argument, sleep should print an error message.
   4. The command-line argument is passed as a string; you can convert it to an integer using atoi (see user/ulib.c).
   5. Use the system call sleep.
   6. See kernel/sysproc.c for the xv6 kernel code that implements the sleep system call (look for sys_sleep), user/user.h for the C definition of sleep callable from a user program, and user/usys.S for the assembler code that jumps from user code into the kernel for sleep.
   7. Make sure main calls exit() in order to exit your program.
   8. Add your sleep program to UPROGS in Makefile; once you've done that, make qemu will compile your program and you'll be able to run it from the xv6 shell.
   9. Look at Kernighan and Ritchie's book The C programming language (second edition) (K&R) to learn about C.

我的实现：
1. 思考：
   在文件`kernel/sysproc.c`中，有`sys_sleep`的实现，即系统调用`sleep`的实现。
   的函数定义为`uint_64 sys_sleep(void)`因为这个函数只被调用，它的参数由全局变量传递（寄存器）。
   
   `sys_sleep()`函数有两种返回值，一种是非正常的`-1`，另一种是正常的`0`。因此外部调用的函数应该要获得这个值一并返回。

   另外在文件`user/user.h`中，`sleep`函数定义为`int sleep(int)`，这个这个定义之所以是两个int，是因为`user/ysys.S`文件中的`sleep`为：
   ```
   .global sleep
    sleep:
    li a7, SYS_sleep
    ecall
    ret
   ```
   
2. 实现：
   注意要修改`Makefile`
   ```
   #include "kernel/types.h"
    #include "user/user.h"

    int
    main(int argc, char *argv[])
    {
    int n;
    if(argc != 2){
        fprintf(2, "Usage: sleep [n secodes]\n");
        exit(1);
    }
    // fprintf(2, "sleep %s\n", argv[1]);
    n = atoi(argv[1]);
    // fprintf(2, "sleep %d\n", n);

    if (0 == sleep(n)){
        exit(0);
    }
    exit(1);

    }
   ```
3. 测试
   Note that make grade runs all tests, including the ones for the assignments below. If you want to run the grade tests for one assignment, type:
    ```
     $ ./grade-lab-util sleep
   ```
    This will run the grade tests that match "sleep". Or, you can type:
    ```
    $ make GRADEFLAGS=sleep grade
    ```
## pingpong

实现`pingpong`调用，通过fork创建子进程，通过pipe进行进程间通信。

提示：



1. Use pipe to create a pipe.

2. Use fork to create a child. 

3. Use read to read from the pipe, and write to write to the pipe.

4. Use getpid to find the process ID of the calling process.

5. Add the program to UPROGS in Makefile.

6. User programs on xv6 have a limited set of library functions available to them. You can see the list in user/user.h; the source (other than for system calls) is in user/ulib.c, user/printf.c, and user/umalloc.c.

我的实现：
1. 思考

    **关于pipe**
    
    pipe的入参是一个整数数组，pipe函数结束后，表示两个文件描述符。如：
    ```
    int p[2];
    pipe(p);
    ```
    其中pipe返回的管道p[0]用于读，p[1]用于写。任何进程如果获取这个pipe的文件描述符就可以从管道中读取或写入，但是信息只能被读取一次。程序的运行会被对文件的读取阻塞。

    **关于fork**
    fork后，文件的描述符在两个进程中都是存在的。因此父进程和子进程都获得同一个pipe，都可以向pipe中写入或读取数据。

2. 实现

    实现的过程中，强化了pingpong的信息来源于另一个进程，验证程序确实是从另一个进程获取的打印信息。
    ```
    #include "kernel/types.h"
    #include "user/user.h"

    int
    main(int argc, char *argv[])
    {
    int p[2];
    int pid, len = 0;
    char msg[1];
    if(argc != 1){
        fprintf(2, "Usage: pingpong\n");
        exit(1);
    }

        pipe(p);
        if(fork() == 0)
        {
        //child
            close(0);
            pid = getpid();
            len = read(p[0], msg, sizeof(msg));
            if(1 != len)
            exit(1);
            fprintf(1, "%d: received p%cng\n",pid,msg[0]);
            msg[0] = 'o';
            len = write(p[1], msg, sizeof(msg));
            if(1 != len)
            exit(1);
            close(p[0]);
            close(p[1]);
            exit(0);
        }
        else
        {
        //parent
            close(0);
            pid = getpid();
            msg[0] = 'i';
            len = write(p[1], msg, sizeof(msg));
            if(1 != len)
            exit(1);
            len = read(p[0], msg, sizeof(msg));
            if(1 != len)
            exit(1);
            fprintf(1, "%d: received p%cng\n",pid,msg[0]);
            close(p[0]);
            close(p[1]);
            exit(0);
        }

    }
    ```
3. 测试

    通过运行命令进行测试
    ```
    ./grade-lab-util pingpong
    ```

## primes 

Your goal is to use pipe and fork to set up the pipeline. The first process feeds the numbers 2 through 35 into the pipeline. For each prime number, you will arrange to create one process that reads from its left neighbor over a pipe and writes to its right neighbor over another pipe. Since xv6 has limited number of file descriptors and processes, the first process can stop at 35.

提示：
1. Be careful to close file descriptors that a process doesn't need, because otherwise your program will run xv6 out of resources before the first process reaches 35.
2. Once the first process reaches 35, it should wait until the entire pipeline terminates, including all children, grandchildren, &c. Thus the main primes process should only exit after all the output has been printed, and after all the other primes processes have exited.
3. Hint: read returns zero when the write-side of a pipe is closed.
4. It's simplest to directly write 32-bit (4-byte) ints to the pipes, rather than using formatted ASCII I/O.
5. You should create the processes in the pipeline only as they are needed.
6. Add the program to UPROGS in Makefile.
---
1. 思考
    1. 子进程不需要管道的输入，同时为了减少管道的文件数量。可以将自己的默认打开的管道0[stdin]关闭。
    2. 如何实现：
        1. 使用pipe构建能与子进程沟通的管道`write_fd`
        2. 使用fork创建子进程，子进程中关闭文件0，同时复制`write_fd[0]`，再关闭write_fd[0]，可以从文件0读取从父进程获取的数据。
        另外子进程中可以关闭`write_fd[1]`，因为子进程不用向父进程传递信息。
        3. 最开始的父进程将2-35写入`write_fd`
        4. 对每个子进程，如果没有输出过质数，则判断是否为质数，是则输出，且再创建一个子进程。
        5. 如果子进程已经输出过质数，则自己也有子进程，则将获得的输入传递给自己的子进程。



2. 实现
    ```c
    #include "kernel/types.h"
    #include "user/user.h"

    int is_prime(int x)
    {
        int i = 2;
        if(x == 1) return 0;
        if(x <= 3) return 1;
        for(i = 2; i * i <= x; i++)
        {
            if(0 == x%i) return 0;
        }
        return 1;
    }

    int
    main(int argc, char *argv[])
    {
        // int read_fd[2];
        int write_fd[2]; // for root process, only write
        int i,first = 1;;
        if(argc != 1){
            fprintf(2, "Usage: primes\n");
            exit(1);
        }
        // pipe(read_fd);
        pipe(write_fd);

        if(0 == fork())
        {
            // child
            first = 1;
            close(0);
            dup(write_fd[0]);
            close(write_fd[0]);// read 0 is read from father process's 1

            close(write_fd[1]);// close father process's 1
            while(read(0,&i,sizeof(int)) == sizeof(int))
            {
                if(first && is_prime(i))
                {
                    first = 0;
                    fprintf(1,"prime %d\n",i); // print to stdout
                    pipe(write_fd); // make a pipe to send number to next child
                    if(0 == fork())
                    {
                        first = 1;
                        close(0);
                        dup(write_fd[0]);
                        close(write_fd[0]);// read 0 is read from father process's 1

                        close(write_fd[1]);// close father process's 1
                    }   
                    else
                    { 
                        close(1);
                        dup(write_fd[1]);
                        close(write_fd[1]); // write to 1 is write to child process
                        // if close 1, child ends
                    }
                }
                else if (!first){
                    write(1,&i,sizeof(int)); // write to child
                }
            }
            close(1);// close 1 to end child
            wait(0);//wait child exit(), guarantee order. For last child, just end.
            exit(0);
        }
        else
        {
            // parent
            close(write_fd[0]);
            for(i = 2; i <=35; i++)
            {
                write(write_fd[1], &i, sizeof(int));
            }
            close(write_fd[1]);
            wait(0);
        }
        exit(0);
    }
    ```
3. 测试

    通过运行命令进行测试
    ```
    ./grade-lab-util primes
    ```

## find 

Write a simple version of the UNIX find program: find all the files in a directory tree with a specific name. Your solution should be in the file `user/find.c`.

提示：
1. Look at user/ls.c to see how to read directories.
2. Use recursion to allow find to descend into sub-directories.
3. Don't recurse into "." and "..".
4. Changes to the file system persist across runs of qemu; to get a clean file system run make clean and then make qemu.//在QEMU的各个运行期间能持久化之前的文件处理，因此需要重新make以获得清空的目录树
5. You'll need to use C strings. Have a look at K&R (the C book), for example Section 5.5.
6. Note that == does not compare strings like in Python. Use strcmp() instead.
7. Add the program to UPROGS in Makefile.

---
1. 思考
    
    1. find 需要两个用户参数，分别是[dir]和[file name]，因此我们需要设置错误提示
    2. 阅读`user/ls.c`，查看如何打开一个文件或目录

2. 实现

    ```c
    // find.c
    #include "kernel/types.h"
    #include "kernel/stat.h"
    #include "user/user.h"
    #include "kernel/fs.h"

    static char *
    _fmtname(char *path)
    {
        static char buf[DIRSIZ + 1];
        char *p;

        // Find first character after last slash.
        for (p = path + strlen(path); p >= path && *p != '/'; p--)
            ;
        p++;

        // Return blank-padded name.
        if (strlen(p) >= DIRSIZ)
            return p;
        memmove(buf, p, strlen(p));
        memset(buf + strlen(p), '\0', DIRSIZ - strlen(p));
        return buf;
    }

    void find(char *path, char *filename)
    {
        char buf[512], *p;
        int fd;
        struct dirent de;
        struct stat st;

        if ((fd = open(path, 0)) < 0)
        {
            fprintf(2, "find: cannot open %s\n", path);
            return;
        }

        if (fstat(fd, &st) < 0)
        {
            fprintf(2, "find: cannot stat %s\n", path);
            close(fd);
            return;
        }

        switch (st.type)
        {
        case T_FILE:
            if (strcmp(_fmtname(path), filename) == 0)
            {
                printf("%s\n", path);
            }
            break;

        case T_DIR:
            if (strlen(path) + 1 + DIRSIZ + 1 > sizeof buf)
            {
                printf("find: path too long\n");
                break;
            }
            strcpy(buf, path);
            p = buf + strlen(buf);
            *p++ = '/';
            while (read(fd, &de, sizeof(de)) == sizeof(de))
            {
                if (de.inum == 0)
                    continue;
                memmove(p, de.name, DIRSIZ);
                p[DIRSIZ] = 0;
                if (stat(buf, &st) < 0)
                {
                    printf("find: cannot stat %s\n", buf);
                    continue;
                }
                switch (st.type)
                {
                case T_FILE:
                    if (strcmp(_fmtname(buf), filename) == 0)
                    {
                        printf("%s\n", buf);
                    }
                    break;
                case T_DIR:
                    if (strcmp(".", _fmtname(buf)) == 0 || strcmp("..", _fmtname(buf)) == 0)
                    {
                        break;
                    }
                    find(buf, filename);
                    break;
                }
            }
            break;
        }
        close(fd);
    }

    int main(int argc, char *argv[])
    {
        if (argc != 3)
        {
            fprintf(2, "Usage: find [dir] [file_name]\n");
            exit(1);
        }
        find(argv[1], argv[2]);
        exit(0);
    }
    ```
3. 测试

    ```
    ./grade-lab-util find
    ```

## xargs

Write a simple version of the UNIX xargs program: read lines from the standard input and run a command for each line, supplying the line as arguments to the command. Your solution should be in the file `user/xargs.c`.

`xargs`命令将左边管道的输出，每一行作为参数传递给xargs的参数种的命令并执行：

```shell
$ echo hello too | xargs echo bye
bye hello too
$
$ echo "1\n2" | xargs -n 1 echo line
line 1
line 2
$
```


1. 提示 
    1. Use fork and exec to invoke the command on each line of input. Use wait in the parent to wait for the child to complete the command.
    2. To read individual lines of input, read a character at a time until a newline ('\n') appears.
    3. kernel/param.h declares MAXARG, which may be useful if you need to declare an argv array.
    4. Add the program to UPROGS in Makefile.
    5. Changes to the file system persist across runs of qemu; to get a clean file system run make clean and then make qemu.

---

1. 实现

```c
#include "kernel/types.h"
#include "kernel/param.h"
#include "user/user.h"

#define BUFFER_SIZE 512

int
main(int argc, char *argv[])
{
    // for xarg it's output is stdout, and it's input is xargs's left pipe(also stdin)

    char buffer[BUFFER_SIZE];
    char * offset = buffer;
    char *xargs_argv[MAXARG];
    int xargs_argc;
    int basic_xargs_argc = argc - 1;
    int ret = 1;
    int i;
    
    if(argc == 1)
    {
        xargs_argv[0] = "echo";
        basic_xargs_argc = 1;
    
    }
    else
    {
        for(i = 1; i < argc; i ++)
        {
            xargs_argv[i-1] = argv[i];
        }
    }
    

    while(1)
    {
        xargs_argc = basic_xargs_argc;
        offset = buffer;
        *offset = 0;
        do
        {
            ret = read(0,offset,sizeof(char));
        }while(offset < buffer+BUFFER_SIZE && *(offset) !='\n' && ret && (offset++||1));
        *offset = 0;

        if(ret)
        {
            xargs_argv[xargs_argc++] = buffer;
            xargs_argv[xargs_argc] = 0;


            if(0 == fork())
            {//child
                // for(i = 0; i < MAXARG && xargs_argv[i] !=0; i++)
                // {
                //     printf("xargv[%d]: %s\n",i, xargs_argv[i]);
                // }
                exec(xargs_argv[0],xargs_argv);
                exit(0);
            }
            else{
                wait(0);
            }
        }
        else
        {
            exit(0);
        }
    }
    exit(0);
}
```
2. 测试

```
./grade-lab-util xargs
```
