# Env init

install on WSL

```shell
$ sudo apt-get update && sudo apt-get upgrade
$ sudo apt-get install git build-essential gdb-multiarch qemu-system-misc gcc-riscv64-linux-gnu binutils-riscv64-linux-gnu
```

## Lab: Xv6 and Unix utilities

### Boot xv6

1. clone code

    ``` 
    git clone git://g.csail.mit.edu/xv6-labs-2021
    ```

2. checkout to `util` branch

    ```
    cd xv6-labs-2021
    git checkout util
    ```

3. finish lab

    完成lab后，可以commit自己的工作：

    ```
    git commit -am 'my solution for util lab exercise 1'
    ```

4. run qemu
    编译qemu，并运行xv6

    ```shell
    make qemu
    ```
    我这里遇到了一些编译问题，需要安装一些工具：

    ```
    sudo apt-get install git build-essential gdb-multiarch qemu-system-misc gcc-riscv64-linux-gnu binutils-riscv64-linux-gnu 
    ```

    之后可以正常编译。qemu中输入`ls`

    ```
    $ ls
    .              1 1 1024
    ..             1 1 1024
    README         2 2 2226
    xargstest.sh   2 3 93
    cat            2 4 23896
    echo           2 5 22728
    forktest       2 6 13080
    grep           2 7 27248
    init           2 8 23824
    kill           2 9 22696
    ln             2 10 22648
    ls             2 11 26128
    mkdir          2 12 22792
    rm             2 13 22784
    sh             2 14 41664
    stressfs       2 15 23800
    usertests      2 16 156008
    grind          2 17 37968
    wc             2 18 25032
    zombie         2 19 22192
    console        3 20 0
    ```

5. `ps`命令

    xv6中没有ps命令，但是可以通过`ctrl-p`打印每个进程的信息

    ```
    $
    1 sleep  init
    2 sleep  sh
    ```

6. 退出qemu

    通过`ctrl-a x`推出qemu
