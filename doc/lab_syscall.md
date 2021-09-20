# lab_syscall

[toc]

## before coding

 read Chapter 2 of the [xv6 book](https://pdos.csail.mit.edu/6.828/2021/xv6/book-riscv-rev1.pdf), and Sections 4.3 and 4.4 of Chapter 4, and related source files:

- The user-space code for systems calls is in `user/user.h` and `user/usys.pl`.
- The kernel-space code is `kernel/syscall.h`, `kernel/syscall.c`.
- The process-related code is `kernel/proc.h` and `kernel/proc.c`.

**file description**

* `user/user.h`: declaration of `syscall` and some useful lib function (like `printf`).
* `user/usys.pl`: Generate usys.S, the stubs for syscalls.
* `kernel/syscall.h`: Macro define of syscall number
* `kernel/syscall.c`: syscall list and syscall argument function( sys call get args from specific register, not stack)
* `kernel/proc.h`: process information data structure
* `kernel/proc.c`: process related function and syscall

## 
