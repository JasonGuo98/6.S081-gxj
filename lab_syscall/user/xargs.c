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

    // char * to_exe[] = {"echo","1",0};
    // exec(to_exe[0],to_exe[1])
    if(argc == 1)
    {
        xargs_argv[0] = "echo";
        basic_xargs_argc = 1;
        // printf("xargs_argv: %s\n","echo");
    
    }
    else
    {
        for(i = 1; i < argc; i ++)
        {
            xargs_argv[i-1] = argv[i];
            // printf("xargs_argv: %s\n",argv[i]);
        }
    }
    

    while(1)
    {
        // printf("line: %d\n",__LINE__);
        xargs_argc = basic_xargs_argc;
        offset = buffer;
        *offset = 0;
        do
        {
            ret = read(0,offset,sizeof(char));
        }while(offset < buffer+BUFFER_SIZE && *(offset) !='\n' && ret && (offset++||1));
        // printf("line: %d\n",__LINE__);
        // printf("ret: %d\n",ret);
        *offset = 0;

        if(ret)
        {
            // printf("read str: %s\n",buffer);
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