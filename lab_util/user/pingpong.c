#include "kernel/types.h"
#include "kernel/stat.h"
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
        close(0);
        pid = getpid();
        len = write(p[1], msg, sizeof(msg));
        len = read(p[0], msg, sizeof(msg));
        fprintf(1, "%d: received pong\n",pid);
        len = write(p[1], msg, sizeof(msg));
        close(p[0]);
        close(p[1]);
        exit(0);
    }
    else
    {
        close(0);
        pid = getpid();
        len = read(p[0], msg, sizeof(msg));
        if(len!=1)
            exit(0);
        fprintf(1, "%d: received ping\n",pid);
        len = write(p[1], msg, sizeof(msg));
        len = read(p[0], msg, sizeof(msg));
        close(p[0]);
        close(p[1]);
        exit(0);
    }

  
}
