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