#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
    int p[2];
    int pid, i;
    if(argc != 1){
    fprintf(2, "Usage: primes\n");
        exit(1);
    }
    pipe(p);

    if(0 == fork())
    {
        // child
        
    }
    else
    {
        // parent
        for(i = 2; i <=35; i++)
        {
            
        }

    }
}