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
      //child
        close(0);
        pid = getpid();
        len = read(p[0], msg, sizeof(msg));
        if(1 != len)
          exit(1);
        fprintf(1, "%d: received ping\n",pid);
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
        len = write(p[1], msg, sizeof(msg));
        if(1 != len)
          exit(1);
        len = read(p[0], msg, sizeof(msg));
        if(1 != len)
          exit(1);
        fprintf(1, "%d: received pong\n",pid);
        close(p[0]);
        close(p[1]);
        exit(0);
    }

  
}
