#include "types.h"
#include "riscv.h"
#include "param.h"
#include "defs.h"
#include "date.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  if(argint(0, &n) < 0)
    return -1;
  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  if(argaddr(0, &p) < 0)
    return -1;
  return wait(p);
}

uint64
sys_sbrk(void)
{
  int addr;
  int n;

  if(argint(0, &n) < 0)
    return -1;
  
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;


  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}


#ifdef LAB_PGTBL

#define MAX_CHECK_N 512

#define MAX_UINT8_BITMAXK_L (MAX_CHECK_N+7)>>3

int
sys_pgaccess(void)
{
  // lab pgtbl: your code here.

  uint64 startaddr;
  int ncheck;
  uint64 u_bitmask;
  if(argaddr(0, &startaddr) < 0)
      return -1;
  if(argint(1, &ncheck) < 0)
      return -1;
  if(argaddr(2, &u_bitmask) < 0)
      return -1;

  if(ncheck > MAX_CHECK_N)
      return -1;


  char k_bitmask[MAX_UINT8_BITMAXK_L];
  memset(k_bitmask, 0, sizeof(k_bitmask));
  struct proc * p = myproc();
  pte_t * pte = 0;
  //pte = walk(p->pagetable, startaddr, 0);
  for(int i = 0; i < ncheck; i++)
  {
    pte = walk(p->pagetable, startaddr + i * 4096, 0);
    if(pte == 0)
        continue;
    if((*(pte) & PTE_V) && (*(pte) & PTE_A))
    {
        *(pte) ^= PTE_A;
        k_bitmask[i >> 3] |= 1<<(i&0x7);
    }
  }
  
  if(copyout(p->pagetable, u_bitmask,  k_bitmask, (ncheck+7)>>3) < 0)
      return -1;
  return 0;
}
#endif

uint64
sys_kill(void)
{
  int pid;

  if(argint(0, &pid) < 0)
    return -1;
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}
