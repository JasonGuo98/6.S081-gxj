# lab_util

[toc]

## sleep

Use sleep sys call.

## pingpong

Note that pipe can transmit info in both child and parent, but read and write in both side.

It means if child write pipe[0], pipe[1]  can be read in both parent and child. If one read, another could not.

## primes 

Use this lab to understand I/O redirection.

## find

Just modify `ls`. Note that the `fmtname` is not suit for `find`.

## xargs

Understand that for `xarg` it's output is `stdout`, and it's input is `xargs`'s left pipe(also `stdin`).

Also understand `exec` replace the origin process, and parent can also `wait` for it.

## time.txt

Add a `time.txt` file with an integer: the total hour to do this lab.

