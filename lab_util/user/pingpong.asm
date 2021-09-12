
user/_pingpong:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	1800                	addi	s0,sp,48
  int p[2];
  int pid, len = 0;
  char msg[1];
  if(argc != 1){
   a:	4785                	li	a5,1
   c:	02f50063          	beq	a0,a5,2c <main+0x2c>
    fprintf(2, "Usage: pingpong\n");
  10:	00001597          	auipc	a1,0x1
  14:	8d058593          	addi	a1,a1,-1840 # 8e0 <malloc+0xe4>
  18:	4509                	li	a0,2
  1a:	00000097          	auipc	ra,0x0
  1e:	6f6080e7          	jalr	1782(ra) # 710 <fprintf>
    exit(1);
  22:	4505                	li	a0,1
  24:	00000097          	auipc	ra,0x0
  28:	3a2080e7          	jalr	930(ra) # 3c6 <exit>
  }

    pipe(p);
  2c:	fd840513          	addi	a0,s0,-40
  30:	00000097          	auipc	ra,0x0
  34:	3a6080e7          	jalr	934(ra) # 3d6 <pipe>
    if(fork() == 0)
  38:	00000097          	auipc	ra,0x0
  3c:	386080e7          	jalr	902(ra) # 3be <fork>
  40:	e141                	bnez	a0,c0 <main+0xc0>
    {
        close(0);
  42:	00000097          	auipc	ra,0x0
  46:	3ac080e7          	jalr	940(ra) # 3ee <close>
        pid = getpid();
  4a:	00000097          	auipc	ra,0x0
  4e:	3fc080e7          	jalr	1020(ra) # 446 <getpid>
  52:	84aa                	mv	s1,a0
        len = write(p[1], msg, sizeof(msg));
  54:	4605                	li	a2,1
  56:	fd040593          	addi	a1,s0,-48
  5a:	fdc42503          	lw	a0,-36(s0)
  5e:	00000097          	auipc	ra,0x0
  62:	388080e7          	jalr	904(ra) # 3e6 <write>
        len = read(p[0], msg, sizeof(msg));
  66:	4605                	li	a2,1
  68:	fd040593          	addi	a1,s0,-48
  6c:	fd842503          	lw	a0,-40(s0)
  70:	00000097          	auipc	ra,0x0
  74:	36e080e7          	jalr	878(ra) # 3de <read>
        fprintf(1, "%d: received pong\n",pid);
  78:	8626                	mv	a2,s1
  7a:	00001597          	auipc	a1,0x1
  7e:	87e58593          	addi	a1,a1,-1922 # 8f8 <malloc+0xfc>
  82:	4505                	li	a0,1
  84:	00000097          	auipc	ra,0x0
  88:	68c080e7          	jalr	1676(ra) # 710 <fprintf>
        len = write(p[1], msg, sizeof(msg));
  8c:	4605                	li	a2,1
  8e:	fd040593          	addi	a1,s0,-48
  92:	fdc42503          	lw	a0,-36(s0)
  96:	00000097          	auipc	ra,0x0
  9a:	350080e7          	jalr	848(ra) # 3e6 <write>
        close(p[0]);
  9e:	fd842503          	lw	a0,-40(s0)
  a2:	00000097          	auipc	ra,0x0
  a6:	34c080e7          	jalr	844(ra) # 3ee <close>
        close(p[1]);
  aa:	fdc42503          	lw	a0,-36(s0)
  ae:	00000097          	auipc	ra,0x0
  b2:	340080e7          	jalr	832(ra) # 3ee <close>
        exit(0);
  b6:	4501                	li	a0,0
  b8:	00000097          	auipc	ra,0x0
  bc:	30e080e7          	jalr	782(ra) # 3c6 <exit>
    }
    else
    {
        close(0);
  c0:	4501                	li	a0,0
  c2:	00000097          	auipc	ra,0x0
  c6:	32c080e7          	jalr	812(ra) # 3ee <close>
        pid = getpid();
  ca:	00000097          	auipc	ra,0x0
  ce:	37c080e7          	jalr	892(ra) # 446 <getpid>
  d2:	84aa                	mv	s1,a0
        len = read(p[0], msg, sizeof(msg));
  d4:	4605                	li	a2,1
  d6:	fd040593          	addi	a1,s0,-48
  da:	fd842503          	lw	a0,-40(s0)
  de:	00000097          	auipc	ra,0x0
  e2:	300080e7          	jalr	768(ra) # 3de <read>
        if(len!=1)
  e6:	4785                	li	a5,1
  e8:	00f50763          	beq	a0,a5,f6 <main+0xf6>
            exit(0);
  ec:	4501                	li	a0,0
  ee:	00000097          	auipc	ra,0x0
  f2:	2d8080e7          	jalr	728(ra) # 3c6 <exit>
        fprintf(1, "%d: received ping\n",pid);
  f6:	8626                	mv	a2,s1
  f8:	00001597          	auipc	a1,0x1
  fc:	81858593          	addi	a1,a1,-2024 # 910 <malloc+0x114>
 100:	4505                	li	a0,1
 102:	00000097          	auipc	ra,0x0
 106:	60e080e7          	jalr	1550(ra) # 710 <fprintf>
        len = write(p[1], msg, sizeof(msg));
 10a:	4605                	li	a2,1
 10c:	fd040593          	addi	a1,s0,-48
 110:	fdc42503          	lw	a0,-36(s0)
 114:	00000097          	auipc	ra,0x0
 118:	2d2080e7          	jalr	722(ra) # 3e6 <write>
        len = read(p[0], msg, sizeof(msg));
 11c:	4605                	li	a2,1
 11e:	fd040593          	addi	a1,s0,-48
 122:	fd842503          	lw	a0,-40(s0)
 126:	00000097          	auipc	ra,0x0
 12a:	2b8080e7          	jalr	696(ra) # 3de <read>
        close(p[0]);
 12e:	fd842503          	lw	a0,-40(s0)
 132:	00000097          	auipc	ra,0x0
 136:	2bc080e7          	jalr	700(ra) # 3ee <close>
        close(p[1]);
 13a:	fdc42503          	lw	a0,-36(s0)
 13e:	00000097          	auipc	ra,0x0
 142:	2b0080e7          	jalr	688(ra) # 3ee <close>
        exit(0);
 146:	4501                	li	a0,0
 148:	00000097          	auipc	ra,0x0
 14c:	27e080e7          	jalr	638(ra) # 3c6 <exit>

0000000000000150 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 150:	1141                	addi	sp,sp,-16
 152:	e422                	sd	s0,8(sp)
 154:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 156:	87aa                	mv	a5,a0
 158:	0585                	addi	a1,a1,1
 15a:	0785                	addi	a5,a5,1
 15c:	fff5c703          	lbu	a4,-1(a1)
 160:	fee78fa3          	sb	a4,-1(a5)
 164:	fb75                	bnez	a4,158 <strcpy+0x8>
    ;
  return os;
}
 166:	6422                	ld	s0,8(sp)
 168:	0141                	addi	sp,sp,16
 16a:	8082                	ret

000000000000016c <strcmp>:

int
strcmp(const char *p, const char *q)
{
 16c:	1141                	addi	sp,sp,-16
 16e:	e422                	sd	s0,8(sp)
 170:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 172:	00054783          	lbu	a5,0(a0)
 176:	cb91                	beqz	a5,18a <strcmp+0x1e>
 178:	0005c703          	lbu	a4,0(a1)
 17c:	00f71763          	bne	a4,a5,18a <strcmp+0x1e>
    p++, q++;
 180:	0505                	addi	a0,a0,1
 182:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 184:	00054783          	lbu	a5,0(a0)
 188:	fbe5                	bnez	a5,178 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 18a:	0005c503          	lbu	a0,0(a1)
}
 18e:	40a7853b          	subw	a0,a5,a0
 192:	6422                	ld	s0,8(sp)
 194:	0141                	addi	sp,sp,16
 196:	8082                	ret

0000000000000198 <strlen>:

uint
strlen(const char *s)
{
 198:	1141                	addi	sp,sp,-16
 19a:	e422                	sd	s0,8(sp)
 19c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 19e:	00054783          	lbu	a5,0(a0)
 1a2:	cf91                	beqz	a5,1be <strlen+0x26>
 1a4:	0505                	addi	a0,a0,1
 1a6:	87aa                	mv	a5,a0
 1a8:	4685                	li	a3,1
 1aa:	9e89                	subw	a3,a3,a0
 1ac:	00f6853b          	addw	a0,a3,a5
 1b0:	0785                	addi	a5,a5,1
 1b2:	fff7c703          	lbu	a4,-1(a5)
 1b6:	fb7d                	bnez	a4,1ac <strlen+0x14>
    ;
  return n;
}
 1b8:	6422                	ld	s0,8(sp)
 1ba:	0141                	addi	sp,sp,16
 1bc:	8082                	ret
  for(n = 0; s[n]; n++)
 1be:	4501                	li	a0,0
 1c0:	bfe5                	j	1b8 <strlen+0x20>

00000000000001c2 <memset>:

void*
memset(void *dst, int c, uint n)
{
 1c2:	1141                	addi	sp,sp,-16
 1c4:	e422                	sd	s0,8(sp)
 1c6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 1c8:	ce09                	beqz	a2,1e2 <memset+0x20>
 1ca:	87aa                	mv	a5,a0
 1cc:	fff6071b          	addiw	a4,a2,-1
 1d0:	1702                	slli	a4,a4,0x20
 1d2:	9301                	srli	a4,a4,0x20
 1d4:	0705                	addi	a4,a4,1
 1d6:	972a                	add	a4,a4,a0
    cdst[i] = c;
 1d8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 1dc:	0785                	addi	a5,a5,1
 1de:	fee79de3          	bne	a5,a4,1d8 <memset+0x16>
  }
  return dst;
}
 1e2:	6422                	ld	s0,8(sp)
 1e4:	0141                	addi	sp,sp,16
 1e6:	8082                	ret

00000000000001e8 <strchr>:

char*
strchr(const char *s, char c)
{
 1e8:	1141                	addi	sp,sp,-16
 1ea:	e422                	sd	s0,8(sp)
 1ec:	0800                	addi	s0,sp,16
  for(; *s; s++)
 1ee:	00054783          	lbu	a5,0(a0)
 1f2:	cb99                	beqz	a5,208 <strchr+0x20>
    if(*s == c)
 1f4:	00f58763          	beq	a1,a5,202 <strchr+0x1a>
  for(; *s; s++)
 1f8:	0505                	addi	a0,a0,1
 1fa:	00054783          	lbu	a5,0(a0)
 1fe:	fbfd                	bnez	a5,1f4 <strchr+0xc>
      return (char*)s;
  return 0;
 200:	4501                	li	a0,0
}
 202:	6422                	ld	s0,8(sp)
 204:	0141                	addi	sp,sp,16
 206:	8082                	ret
  return 0;
 208:	4501                	li	a0,0
 20a:	bfe5                	j	202 <strchr+0x1a>

000000000000020c <gets>:

char*
gets(char *buf, int max)
{
 20c:	711d                	addi	sp,sp,-96
 20e:	ec86                	sd	ra,88(sp)
 210:	e8a2                	sd	s0,80(sp)
 212:	e4a6                	sd	s1,72(sp)
 214:	e0ca                	sd	s2,64(sp)
 216:	fc4e                	sd	s3,56(sp)
 218:	f852                	sd	s4,48(sp)
 21a:	f456                	sd	s5,40(sp)
 21c:	f05a                	sd	s6,32(sp)
 21e:	ec5e                	sd	s7,24(sp)
 220:	1080                	addi	s0,sp,96
 222:	8baa                	mv	s7,a0
 224:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 226:	892a                	mv	s2,a0
 228:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 22a:	4aa9                	li	s5,10
 22c:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 22e:	89a6                	mv	s3,s1
 230:	2485                	addiw	s1,s1,1
 232:	0344d863          	bge	s1,s4,262 <gets+0x56>
    cc = read(0, &c, 1);
 236:	4605                	li	a2,1
 238:	faf40593          	addi	a1,s0,-81
 23c:	4501                	li	a0,0
 23e:	00000097          	auipc	ra,0x0
 242:	1a0080e7          	jalr	416(ra) # 3de <read>
    if(cc < 1)
 246:	00a05e63          	blez	a0,262 <gets+0x56>
    buf[i++] = c;
 24a:	faf44783          	lbu	a5,-81(s0)
 24e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 252:	01578763          	beq	a5,s5,260 <gets+0x54>
 256:	0905                	addi	s2,s2,1
 258:	fd679be3          	bne	a5,s6,22e <gets+0x22>
  for(i=0; i+1 < max; ){
 25c:	89a6                	mv	s3,s1
 25e:	a011                	j	262 <gets+0x56>
 260:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 262:	99de                	add	s3,s3,s7
 264:	00098023          	sb	zero,0(s3)
  return buf;
}
 268:	855e                	mv	a0,s7
 26a:	60e6                	ld	ra,88(sp)
 26c:	6446                	ld	s0,80(sp)
 26e:	64a6                	ld	s1,72(sp)
 270:	6906                	ld	s2,64(sp)
 272:	79e2                	ld	s3,56(sp)
 274:	7a42                	ld	s4,48(sp)
 276:	7aa2                	ld	s5,40(sp)
 278:	7b02                	ld	s6,32(sp)
 27a:	6be2                	ld	s7,24(sp)
 27c:	6125                	addi	sp,sp,96
 27e:	8082                	ret

0000000000000280 <stat>:

int
stat(const char *n, struct stat *st)
{
 280:	1101                	addi	sp,sp,-32
 282:	ec06                	sd	ra,24(sp)
 284:	e822                	sd	s0,16(sp)
 286:	e426                	sd	s1,8(sp)
 288:	e04a                	sd	s2,0(sp)
 28a:	1000                	addi	s0,sp,32
 28c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 28e:	4581                	li	a1,0
 290:	00000097          	auipc	ra,0x0
 294:	176080e7          	jalr	374(ra) # 406 <open>
  if(fd < 0)
 298:	02054563          	bltz	a0,2c2 <stat+0x42>
 29c:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 29e:	85ca                	mv	a1,s2
 2a0:	00000097          	auipc	ra,0x0
 2a4:	17e080e7          	jalr	382(ra) # 41e <fstat>
 2a8:	892a                	mv	s2,a0
  close(fd);
 2aa:	8526                	mv	a0,s1
 2ac:	00000097          	auipc	ra,0x0
 2b0:	142080e7          	jalr	322(ra) # 3ee <close>
  return r;
}
 2b4:	854a                	mv	a0,s2
 2b6:	60e2                	ld	ra,24(sp)
 2b8:	6442                	ld	s0,16(sp)
 2ba:	64a2                	ld	s1,8(sp)
 2bc:	6902                	ld	s2,0(sp)
 2be:	6105                	addi	sp,sp,32
 2c0:	8082                	ret
    return -1;
 2c2:	597d                	li	s2,-1
 2c4:	bfc5                	j	2b4 <stat+0x34>

00000000000002c6 <atoi>:

int
atoi(const char *s)
{
 2c6:	1141                	addi	sp,sp,-16
 2c8:	e422                	sd	s0,8(sp)
 2ca:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 2cc:	00054603          	lbu	a2,0(a0)
 2d0:	fd06079b          	addiw	a5,a2,-48
 2d4:	0ff7f793          	andi	a5,a5,255
 2d8:	4725                	li	a4,9
 2da:	02f76963          	bltu	a4,a5,30c <atoi+0x46>
 2de:	86aa                	mv	a3,a0
  n = 0;
 2e0:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 2e2:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 2e4:	0685                	addi	a3,a3,1
 2e6:	0025179b          	slliw	a5,a0,0x2
 2ea:	9fa9                	addw	a5,a5,a0
 2ec:	0017979b          	slliw	a5,a5,0x1
 2f0:	9fb1                	addw	a5,a5,a2
 2f2:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 2f6:	0006c603          	lbu	a2,0(a3)
 2fa:	fd06071b          	addiw	a4,a2,-48
 2fe:	0ff77713          	andi	a4,a4,255
 302:	fee5f1e3          	bgeu	a1,a4,2e4 <atoi+0x1e>
  return n;
}
 306:	6422                	ld	s0,8(sp)
 308:	0141                	addi	sp,sp,16
 30a:	8082                	ret
  n = 0;
 30c:	4501                	li	a0,0
 30e:	bfe5                	j	306 <atoi+0x40>

0000000000000310 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 310:	1141                	addi	sp,sp,-16
 312:	e422                	sd	s0,8(sp)
 314:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 316:	02b57663          	bgeu	a0,a1,342 <memmove+0x32>
    while(n-- > 0)
 31a:	02c05163          	blez	a2,33c <memmove+0x2c>
 31e:	fff6079b          	addiw	a5,a2,-1
 322:	1782                	slli	a5,a5,0x20
 324:	9381                	srli	a5,a5,0x20
 326:	0785                	addi	a5,a5,1
 328:	97aa                	add	a5,a5,a0
  dst = vdst;
 32a:	872a                	mv	a4,a0
      *dst++ = *src++;
 32c:	0585                	addi	a1,a1,1
 32e:	0705                	addi	a4,a4,1
 330:	fff5c683          	lbu	a3,-1(a1)
 334:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 338:	fee79ae3          	bne	a5,a4,32c <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 33c:	6422                	ld	s0,8(sp)
 33e:	0141                	addi	sp,sp,16
 340:	8082                	ret
    dst += n;
 342:	00c50733          	add	a4,a0,a2
    src += n;
 346:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 348:	fec05ae3          	blez	a2,33c <memmove+0x2c>
 34c:	fff6079b          	addiw	a5,a2,-1
 350:	1782                	slli	a5,a5,0x20
 352:	9381                	srli	a5,a5,0x20
 354:	fff7c793          	not	a5,a5
 358:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 35a:	15fd                	addi	a1,a1,-1
 35c:	177d                	addi	a4,a4,-1
 35e:	0005c683          	lbu	a3,0(a1)
 362:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 366:	fee79ae3          	bne	a5,a4,35a <memmove+0x4a>
 36a:	bfc9                	j	33c <memmove+0x2c>

000000000000036c <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 36c:	1141                	addi	sp,sp,-16
 36e:	e422                	sd	s0,8(sp)
 370:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 372:	ca05                	beqz	a2,3a2 <memcmp+0x36>
 374:	fff6069b          	addiw	a3,a2,-1
 378:	1682                	slli	a3,a3,0x20
 37a:	9281                	srli	a3,a3,0x20
 37c:	0685                	addi	a3,a3,1
 37e:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 380:	00054783          	lbu	a5,0(a0)
 384:	0005c703          	lbu	a4,0(a1)
 388:	00e79863          	bne	a5,a4,398 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 38c:	0505                	addi	a0,a0,1
    p2++;
 38e:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 390:	fed518e3          	bne	a0,a3,380 <memcmp+0x14>
  }
  return 0;
 394:	4501                	li	a0,0
 396:	a019                	j	39c <memcmp+0x30>
      return *p1 - *p2;
 398:	40e7853b          	subw	a0,a5,a4
}
 39c:	6422                	ld	s0,8(sp)
 39e:	0141                	addi	sp,sp,16
 3a0:	8082                	ret
  return 0;
 3a2:	4501                	li	a0,0
 3a4:	bfe5                	j	39c <memcmp+0x30>

00000000000003a6 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 3a6:	1141                	addi	sp,sp,-16
 3a8:	e406                	sd	ra,8(sp)
 3aa:	e022                	sd	s0,0(sp)
 3ac:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 3ae:	00000097          	auipc	ra,0x0
 3b2:	f62080e7          	jalr	-158(ra) # 310 <memmove>
}
 3b6:	60a2                	ld	ra,8(sp)
 3b8:	6402                	ld	s0,0(sp)
 3ba:	0141                	addi	sp,sp,16
 3bc:	8082                	ret

00000000000003be <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 3be:	4885                	li	a7,1
 ecall
 3c0:	00000073          	ecall
 ret
 3c4:	8082                	ret

00000000000003c6 <exit>:
.global exit
exit:
 li a7, SYS_exit
 3c6:	4889                	li	a7,2
 ecall
 3c8:	00000073          	ecall
 ret
 3cc:	8082                	ret

00000000000003ce <wait>:
.global wait
wait:
 li a7, SYS_wait
 3ce:	488d                	li	a7,3
 ecall
 3d0:	00000073          	ecall
 ret
 3d4:	8082                	ret

00000000000003d6 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 3d6:	4891                	li	a7,4
 ecall
 3d8:	00000073          	ecall
 ret
 3dc:	8082                	ret

00000000000003de <read>:
.global read
read:
 li a7, SYS_read
 3de:	4895                	li	a7,5
 ecall
 3e0:	00000073          	ecall
 ret
 3e4:	8082                	ret

00000000000003e6 <write>:
.global write
write:
 li a7, SYS_write
 3e6:	48c1                	li	a7,16
 ecall
 3e8:	00000073          	ecall
 ret
 3ec:	8082                	ret

00000000000003ee <close>:
.global close
close:
 li a7, SYS_close
 3ee:	48d5                	li	a7,21
 ecall
 3f0:	00000073          	ecall
 ret
 3f4:	8082                	ret

00000000000003f6 <kill>:
.global kill
kill:
 li a7, SYS_kill
 3f6:	4899                	li	a7,6
 ecall
 3f8:	00000073          	ecall
 ret
 3fc:	8082                	ret

00000000000003fe <exec>:
.global exec
exec:
 li a7, SYS_exec
 3fe:	489d                	li	a7,7
 ecall
 400:	00000073          	ecall
 ret
 404:	8082                	ret

0000000000000406 <open>:
.global open
open:
 li a7, SYS_open
 406:	48bd                	li	a7,15
 ecall
 408:	00000073          	ecall
 ret
 40c:	8082                	ret

000000000000040e <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 40e:	48c5                	li	a7,17
 ecall
 410:	00000073          	ecall
 ret
 414:	8082                	ret

0000000000000416 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 416:	48c9                	li	a7,18
 ecall
 418:	00000073          	ecall
 ret
 41c:	8082                	ret

000000000000041e <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 41e:	48a1                	li	a7,8
 ecall
 420:	00000073          	ecall
 ret
 424:	8082                	ret

0000000000000426 <link>:
.global link
link:
 li a7, SYS_link
 426:	48cd                	li	a7,19
 ecall
 428:	00000073          	ecall
 ret
 42c:	8082                	ret

000000000000042e <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 42e:	48d1                	li	a7,20
 ecall
 430:	00000073          	ecall
 ret
 434:	8082                	ret

0000000000000436 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 436:	48a5                	li	a7,9
 ecall
 438:	00000073          	ecall
 ret
 43c:	8082                	ret

000000000000043e <dup>:
.global dup
dup:
 li a7, SYS_dup
 43e:	48a9                	li	a7,10
 ecall
 440:	00000073          	ecall
 ret
 444:	8082                	ret

0000000000000446 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 446:	48ad                	li	a7,11
 ecall
 448:	00000073          	ecall
 ret
 44c:	8082                	ret

000000000000044e <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 44e:	48b1                	li	a7,12
 ecall
 450:	00000073          	ecall
 ret
 454:	8082                	ret

0000000000000456 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 456:	48b5                	li	a7,13
 ecall
 458:	00000073          	ecall
 ret
 45c:	8082                	ret

000000000000045e <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 45e:	48b9                	li	a7,14
 ecall
 460:	00000073          	ecall
 ret
 464:	8082                	ret

0000000000000466 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 466:	1101                	addi	sp,sp,-32
 468:	ec06                	sd	ra,24(sp)
 46a:	e822                	sd	s0,16(sp)
 46c:	1000                	addi	s0,sp,32
 46e:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 472:	4605                	li	a2,1
 474:	fef40593          	addi	a1,s0,-17
 478:	00000097          	auipc	ra,0x0
 47c:	f6e080e7          	jalr	-146(ra) # 3e6 <write>
}
 480:	60e2                	ld	ra,24(sp)
 482:	6442                	ld	s0,16(sp)
 484:	6105                	addi	sp,sp,32
 486:	8082                	ret

0000000000000488 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 488:	7139                	addi	sp,sp,-64
 48a:	fc06                	sd	ra,56(sp)
 48c:	f822                	sd	s0,48(sp)
 48e:	f426                	sd	s1,40(sp)
 490:	f04a                	sd	s2,32(sp)
 492:	ec4e                	sd	s3,24(sp)
 494:	0080                	addi	s0,sp,64
 496:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 498:	c299                	beqz	a3,49e <printint+0x16>
 49a:	0805c863          	bltz	a1,52a <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 49e:	2581                	sext.w	a1,a1
  neg = 0;
 4a0:	4881                	li	a7,0
 4a2:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 4a6:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 4a8:	2601                	sext.w	a2,a2
 4aa:	00000517          	auipc	a0,0x0
 4ae:	48650513          	addi	a0,a0,1158 # 930 <digits>
 4b2:	883a                	mv	a6,a4
 4b4:	2705                	addiw	a4,a4,1
 4b6:	02c5f7bb          	remuw	a5,a1,a2
 4ba:	1782                	slli	a5,a5,0x20
 4bc:	9381                	srli	a5,a5,0x20
 4be:	97aa                	add	a5,a5,a0
 4c0:	0007c783          	lbu	a5,0(a5)
 4c4:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 4c8:	0005879b          	sext.w	a5,a1
 4cc:	02c5d5bb          	divuw	a1,a1,a2
 4d0:	0685                	addi	a3,a3,1
 4d2:	fec7f0e3          	bgeu	a5,a2,4b2 <printint+0x2a>
  if(neg)
 4d6:	00088b63          	beqz	a7,4ec <printint+0x64>
    buf[i++] = '-';
 4da:	fd040793          	addi	a5,s0,-48
 4de:	973e                	add	a4,a4,a5
 4e0:	02d00793          	li	a5,45
 4e4:	fef70823          	sb	a5,-16(a4)
 4e8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 4ec:	02e05863          	blez	a4,51c <printint+0x94>
 4f0:	fc040793          	addi	a5,s0,-64
 4f4:	00e78933          	add	s2,a5,a4
 4f8:	fff78993          	addi	s3,a5,-1
 4fc:	99ba                	add	s3,s3,a4
 4fe:	377d                	addiw	a4,a4,-1
 500:	1702                	slli	a4,a4,0x20
 502:	9301                	srli	a4,a4,0x20
 504:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 508:	fff94583          	lbu	a1,-1(s2)
 50c:	8526                	mv	a0,s1
 50e:	00000097          	auipc	ra,0x0
 512:	f58080e7          	jalr	-168(ra) # 466 <putc>
  while(--i >= 0)
 516:	197d                	addi	s2,s2,-1
 518:	ff3918e3          	bne	s2,s3,508 <printint+0x80>
}
 51c:	70e2                	ld	ra,56(sp)
 51e:	7442                	ld	s0,48(sp)
 520:	74a2                	ld	s1,40(sp)
 522:	7902                	ld	s2,32(sp)
 524:	69e2                	ld	s3,24(sp)
 526:	6121                	addi	sp,sp,64
 528:	8082                	ret
    x = -xx;
 52a:	40b005bb          	negw	a1,a1
    neg = 1;
 52e:	4885                	li	a7,1
    x = -xx;
 530:	bf8d                	j	4a2 <printint+0x1a>

0000000000000532 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 532:	7119                	addi	sp,sp,-128
 534:	fc86                	sd	ra,120(sp)
 536:	f8a2                	sd	s0,112(sp)
 538:	f4a6                	sd	s1,104(sp)
 53a:	f0ca                	sd	s2,96(sp)
 53c:	ecce                	sd	s3,88(sp)
 53e:	e8d2                	sd	s4,80(sp)
 540:	e4d6                	sd	s5,72(sp)
 542:	e0da                	sd	s6,64(sp)
 544:	fc5e                	sd	s7,56(sp)
 546:	f862                	sd	s8,48(sp)
 548:	f466                	sd	s9,40(sp)
 54a:	f06a                	sd	s10,32(sp)
 54c:	ec6e                	sd	s11,24(sp)
 54e:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 550:	0005c903          	lbu	s2,0(a1)
 554:	18090f63          	beqz	s2,6f2 <vprintf+0x1c0>
 558:	8aaa                	mv	s5,a0
 55a:	8b32                	mv	s6,a2
 55c:	00158493          	addi	s1,a1,1
  state = 0;
 560:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 562:	02500a13          	li	s4,37
      if(c == 'd'){
 566:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 56a:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 56e:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 572:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 576:	00000b97          	auipc	s7,0x0
 57a:	3bab8b93          	addi	s7,s7,954 # 930 <digits>
 57e:	a839                	j	59c <vprintf+0x6a>
        putc(fd, c);
 580:	85ca                	mv	a1,s2
 582:	8556                	mv	a0,s5
 584:	00000097          	auipc	ra,0x0
 588:	ee2080e7          	jalr	-286(ra) # 466 <putc>
 58c:	a019                	j	592 <vprintf+0x60>
    } else if(state == '%'){
 58e:	01498f63          	beq	s3,s4,5ac <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 592:	0485                	addi	s1,s1,1
 594:	fff4c903          	lbu	s2,-1(s1)
 598:	14090d63          	beqz	s2,6f2 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 59c:	0009079b          	sext.w	a5,s2
    if(state == 0){
 5a0:	fe0997e3          	bnez	s3,58e <vprintf+0x5c>
      if(c == '%'){
 5a4:	fd479ee3          	bne	a5,s4,580 <vprintf+0x4e>
        state = '%';
 5a8:	89be                	mv	s3,a5
 5aa:	b7e5                	j	592 <vprintf+0x60>
      if(c == 'd'){
 5ac:	05878063          	beq	a5,s8,5ec <vprintf+0xba>
      } else if(c == 'l') {
 5b0:	05978c63          	beq	a5,s9,608 <vprintf+0xd6>
      } else if(c == 'x') {
 5b4:	07a78863          	beq	a5,s10,624 <vprintf+0xf2>
      } else if(c == 'p') {
 5b8:	09b78463          	beq	a5,s11,640 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 5bc:	07300713          	li	a4,115
 5c0:	0ce78663          	beq	a5,a4,68c <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 5c4:	06300713          	li	a4,99
 5c8:	0ee78e63          	beq	a5,a4,6c4 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 5cc:	11478863          	beq	a5,s4,6dc <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 5d0:	85d2                	mv	a1,s4
 5d2:	8556                	mv	a0,s5
 5d4:	00000097          	auipc	ra,0x0
 5d8:	e92080e7          	jalr	-366(ra) # 466 <putc>
        putc(fd, c);
 5dc:	85ca                	mv	a1,s2
 5de:	8556                	mv	a0,s5
 5e0:	00000097          	auipc	ra,0x0
 5e4:	e86080e7          	jalr	-378(ra) # 466 <putc>
      }
      state = 0;
 5e8:	4981                	li	s3,0
 5ea:	b765                	j	592 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 5ec:	008b0913          	addi	s2,s6,8
 5f0:	4685                	li	a3,1
 5f2:	4629                	li	a2,10
 5f4:	000b2583          	lw	a1,0(s6)
 5f8:	8556                	mv	a0,s5
 5fa:	00000097          	auipc	ra,0x0
 5fe:	e8e080e7          	jalr	-370(ra) # 488 <printint>
 602:	8b4a                	mv	s6,s2
      state = 0;
 604:	4981                	li	s3,0
 606:	b771                	j	592 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 608:	008b0913          	addi	s2,s6,8
 60c:	4681                	li	a3,0
 60e:	4629                	li	a2,10
 610:	000b2583          	lw	a1,0(s6)
 614:	8556                	mv	a0,s5
 616:	00000097          	auipc	ra,0x0
 61a:	e72080e7          	jalr	-398(ra) # 488 <printint>
 61e:	8b4a                	mv	s6,s2
      state = 0;
 620:	4981                	li	s3,0
 622:	bf85                	j	592 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 624:	008b0913          	addi	s2,s6,8
 628:	4681                	li	a3,0
 62a:	4641                	li	a2,16
 62c:	000b2583          	lw	a1,0(s6)
 630:	8556                	mv	a0,s5
 632:	00000097          	auipc	ra,0x0
 636:	e56080e7          	jalr	-426(ra) # 488 <printint>
 63a:	8b4a                	mv	s6,s2
      state = 0;
 63c:	4981                	li	s3,0
 63e:	bf91                	j	592 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 640:	008b0793          	addi	a5,s6,8
 644:	f8f43423          	sd	a5,-120(s0)
 648:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 64c:	03000593          	li	a1,48
 650:	8556                	mv	a0,s5
 652:	00000097          	auipc	ra,0x0
 656:	e14080e7          	jalr	-492(ra) # 466 <putc>
  putc(fd, 'x');
 65a:	85ea                	mv	a1,s10
 65c:	8556                	mv	a0,s5
 65e:	00000097          	auipc	ra,0x0
 662:	e08080e7          	jalr	-504(ra) # 466 <putc>
 666:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 668:	03c9d793          	srli	a5,s3,0x3c
 66c:	97de                	add	a5,a5,s7
 66e:	0007c583          	lbu	a1,0(a5)
 672:	8556                	mv	a0,s5
 674:	00000097          	auipc	ra,0x0
 678:	df2080e7          	jalr	-526(ra) # 466 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 67c:	0992                	slli	s3,s3,0x4
 67e:	397d                	addiw	s2,s2,-1
 680:	fe0914e3          	bnez	s2,668 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 684:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 688:	4981                	li	s3,0
 68a:	b721                	j	592 <vprintf+0x60>
        s = va_arg(ap, char*);
 68c:	008b0993          	addi	s3,s6,8
 690:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 694:	02090163          	beqz	s2,6b6 <vprintf+0x184>
        while(*s != 0){
 698:	00094583          	lbu	a1,0(s2)
 69c:	c9a1                	beqz	a1,6ec <vprintf+0x1ba>
          putc(fd, *s);
 69e:	8556                	mv	a0,s5
 6a0:	00000097          	auipc	ra,0x0
 6a4:	dc6080e7          	jalr	-570(ra) # 466 <putc>
          s++;
 6a8:	0905                	addi	s2,s2,1
        while(*s != 0){
 6aa:	00094583          	lbu	a1,0(s2)
 6ae:	f9e5                	bnez	a1,69e <vprintf+0x16c>
        s = va_arg(ap, char*);
 6b0:	8b4e                	mv	s6,s3
      state = 0;
 6b2:	4981                	li	s3,0
 6b4:	bdf9                	j	592 <vprintf+0x60>
          s = "(null)";
 6b6:	00000917          	auipc	s2,0x0
 6ba:	27290913          	addi	s2,s2,626 # 928 <malloc+0x12c>
        while(*s != 0){
 6be:	02800593          	li	a1,40
 6c2:	bff1                	j	69e <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 6c4:	008b0913          	addi	s2,s6,8
 6c8:	000b4583          	lbu	a1,0(s6)
 6cc:	8556                	mv	a0,s5
 6ce:	00000097          	auipc	ra,0x0
 6d2:	d98080e7          	jalr	-616(ra) # 466 <putc>
 6d6:	8b4a                	mv	s6,s2
      state = 0;
 6d8:	4981                	li	s3,0
 6da:	bd65                	j	592 <vprintf+0x60>
        putc(fd, c);
 6dc:	85d2                	mv	a1,s4
 6de:	8556                	mv	a0,s5
 6e0:	00000097          	auipc	ra,0x0
 6e4:	d86080e7          	jalr	-634(ra) # 466 <putc>
      state = 0;
 6e8:	4981                	li	s3,0
 6ea:	b565                	j	592 <vprintf+0x60>
        s = va_arg(ap, char*);
 6ec:	8b4e                	mv	s6,s3
      state = 0;
 6ee:	4981                	li	s3,0
 6f0:	b54d                	j	592 <vprintf+0x60>
    }
  }
}
 6f2:	70e6                	ld	ra,120(sp)
 6f4:	7446                	ld	s0,112(sp)
 6f6:	74a6                	ld	s1,104(sp)
 6f8:	7906                	ld	s2,96(sp)
 6fa:	69e6                	ld	s3,88(sp)
 6fc:	6a46                	ld	s4,80(sp)
 6fe:	6aa6                	ld	s5,72(sp)
 700:	6b06                	ld	s6,64(sp)
 702:	7be2                	ld	s7,56(sp)
 704:	7c42                	ld	s8,48(sp)
 706:	7ca2                	ld	s9,40(sp)
 708:	7d02                	ld	s10,32(sp)
 70a:	6de2                	ld	s11,24(sp)
 70c:	6109                	addi	sp,sp,128
 70e:	8082                	ret

0000000000000710 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 710:	715d                	addi	sp,sp,-80
 712:	ec06                	sd	ra,24(sp)
 714:	e822                	sd	s0,16(sp)
 716:	1000                	addi	s0,sp,32
 718:	e010                	sd	a2,0(s0)
 71a:	e414                	sd	a3,8(s0)
 71c:	e818                	sd	a4,16(s0)
 71e:	ec1c                	sd	a5,24(s0)
 720:	03043023          	sd	a6,32(s0)
 724:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 728:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 72c:	8622                	mv	a2,s0
 72e:	00000097          	auipc	ra,0x0
 732:	e04080e7          	jalr	-508(ra) # 532 <vprintf>
}
 736:	60e2                	ld	ra,24(sp)
 738:	6442                	ld	s0,16(sp)
 73a:	6161                	addi	sp,sp,80
 73c:	8082                	ret

000000000000073e <printf>:

void
printf(const char *fmt, ...)
{
 73e:	711d                	addi	sp,sp,-96
 740:	ec06                	sd	ra,24(sp)
 742:	e822                	sd	s0,16(sp)
 744:	1000                	addi	s0,sp,32
 746:	e40c                	sd	a1,8(s0)
 748:	e810                	sd	a2,16(s0)
 74a:	ec14                	sd	a3,24(s0)
 74c:	f018                	sd	a4,32(s0)
 74e:	f41c                	sd	a5,40(s0)
 750:	03043823          	sd	a6,48(s0)
 754:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 758:	00840613          	addi	a2,s0,8
 75c:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 760:	85aa                	mv	a1,a0
 762:	4505                	li	a0,1
 764:	00000097          	auipc	ra,0x0
 768:	dce080e7          	jalr	-562(ra) # 532 <vprintf>
}
 76c:	60e2                	ld	ra,24(sp)
 76e:	6442                	ld	s0,16(sp)
 770:	6125                	addi	sp,sp,96
 772:	8082                	ret

0000000000000774 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 774:	1141                	addi	sp,sp,-16
 776:	e422                	sd	s0,8(sp)
 778:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 77a:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 77e:	00000797          	auipc	a5,0x0
 782:	1ca7b783          	ld	a5,458(a5) # 948 <freep>
 786:	a805                	j	7b6 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 788:	4618                	lw	a4,8(a2)
 78a:	9db9                	addw	a1,a1,a4
 78c:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 790:	6398                	ld	a4,0(a5)
 792:	6318                	ld	a4,0(a4)
 794:	fee53823          	sd	a4,-16(a0)
 798:	a091                	j	7dc <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 79a:	ff852703          	lw	a4,-8(a0)
 79e:	9e39                	addw	a2,a2,a4
 7a0:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 7a2:	ff053703          	ld	a4,-16(a0)
 7a6:	e398                	sd	a4,0(a5)
 7a8:	a099                	j	7ee <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7aa:	6398                	ld	a4,0(a5)
 7ac:	00e7e463          	bltu	a5,a4,7b4 <free+0x40>
 7b0:	00e6ea63          	bltu	a3,a4,7c4 <free+0x50>
{
 7b4:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7b6:	fed7fae3          	bgeu	a5,a3,7aa <free+0x36>
 7ba:	6398                	ld	a4,0(a5)
 7bc:	00e6e463          	bltu	a3,a4,7c4 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7c0:	fee7eae3          	bltu	a5,a4,7b4 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 7c4:	ff852583          	lw	a1,-8(a0)
 7c8:	6390                	ld	a2,0(a5)
 7ca:	02059713          	slli	a4,a1,0x20
 7ce:	9301                	srli	a4,a4,0x20
 7d0:	0712                	slli	a4,a4,0x4
 7d2:	9736                	add	a4,a4,a3
 7d4:	fae60ae3          	beq	a2,a4,788 <free+0x14>
    bp->s.ptr = p->s.ptr;
 7d8:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 7dc:	4790                	lw	a2,8(a5)
 7de:	02061713          	slli	a4,a2,0x20
 7e2:	9301                	srli	a4,a4,0x20
 7e4:	0712                	slli	a4,a4,0x4
 7e6:	973e                	add	a4,a4,a5
 7e8:	fae689e3          	beq	a3,a4,79a <free+0x26>
  } else
    p->s.ptr = bp;
 7ec:	e394                	sd	a3,0(a5)
  freep = p;
 7ee:	00000717          	auipc	a4,0x0
 7f2:	14f73d23          	sd	a5,346(a4) # 948 <freep>
}
 7f6:	6422                	ld	s0,8(sp)
 7f8:	0141                	addi	sp,sp,16
 7fa:	8082                	ret

00000000000007fc <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 7fc:	7139                	addi	sp,sp,-64
 7fe:	fc06                	sd	ra,56(sp)
 800:	f822                	sd	s0,48(sp)
 802:	f426                	sd	s1,40(sp)
 804:	f04a                	sd	s2,32(sp)
 806:	ec4e                	sd	s3,24(sp)
 808:	e852                	sd	s4,16(sp)
 80a:	e456                	sd	s5,8(sp)
 80c:	e05a                	sd	s6,0(sp)
 80e:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 810:	02051493          	slli	s1,a0,0x20
 814:	9081                	srli	s1,s1,0x20
 816:	04bd                	addi	s1,s1,15
 818:	8091                	srli	s1,s1,0x4
 81a:	0014899b          	addiw	s3,s1,1
 81e:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 820:	00000517          	auipc	a0,0x0
 824:	12853503          	ld	a0,296(a0) # 948 <freep>
 828:	c515                	beqz	a0,854 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 82a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 82c:	4798                	lw	a4,8(a5)
 82e:	02977f63          	bgeu	a4,s1,86c <malloc+0x70>
 832:	8a4e                	mv	s4,s3
 834:	0009871b          	sext.w	a4,s3
 838:	6685                	lui	a3,0x1
 83a:	00d77363          	bgeu	a4,a3,840 <malloc+0x44>
 83e:	6a05                	lui	s4,0x1
 840:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 844:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 848:	00000917          	auipc	s2,0x0
 84c:	10090913          	addi	s2,s2,256 # 948 <freep>
  if(p == (char*)-1)
 850:	5afd                	li	s5,-1
 852:	a88d                	j	8c4 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 854:	00000797          	auipc	a5,0x0
 858:	0fc78793          	addi	a5,a5,252 # 950 <base>
 85c:	00000717          	auipc	a4,0x0
 860:	0ef73623          	sd	a5,236(a4) # 948 <freep>
 864:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 866:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 86a:	b7e1                	j	832 <malloc+0x36>
      if(p->s.size == nunits)
 86c:	02e48b63          	beq	s1,a4,8a2 <malloc+0xa6>
        p->s.size -= nunits;
 870:	4137073b          	subw	a4,a4,s3
 874:	c798                	sw	a4,8(a5)
        p += p->s.size;
 876:	1702                	slli	a4,a4,0x20
 878:	9301                	srli	a4,a4,0x20
 87a:	0712                	slli	a4,a4,0x4
 87c:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 87e:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 882:	00000717          	auipc	a4,0x0
 886:	0ca73323          	sd	a0,198(a4) # 948 <freep>
      return (void*)(p + 1);
 88a:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 88e:	70e2                	ld	ra,56(sp)
 890:	7442                	ld	s0,48(sp)
 892:	74a2                	ld	s1,40(sp)
 894:	7902                	ld	s2,32(sp)
 896:	69e2                	ld	s3,24(sp)
 898:	6a42                	ld	s4,16(sp)
 89a:	6aa2                	ld	s5,8(sp)
 89c:	6b02                	ld	s6,0(sp)
 89e:	6121                	addi	sp,sp,64
 8a0:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 8a2:	6398                	ld	a4,0(a5)
 8a4:	e118                	sd	a4,0(a0)
 8a6:	bff1                	j	882 <malloc+0x86>
  hp->s.size = nu;
 8a8:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 8ac:	0541                	addi	a0,a0,16
 8ae:	00000097          	auipc	ra,0x0
 8b2:	ec6080e7          	jalr	-314(ra) # 774 <free>
  return freep;
 8b6:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 8ba:	d971                	beqz	a0,88e <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8bc:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8be:	4798                	lw	a4,8(a5)
 8c0:	fa9776e3          	bgeu	a4,s1,86c <malloc+0x70>
    if(p == freep)
 8c4:	00093703          	ld	a4,0(s2)
 8c8:	853e                	mv	a0,a5
 8ca:	fef719e3          	bne	a4,a5,8bc <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 8ce:	8552                	mv	a0,s4
 8d0:	00000097          	auipc	ra,0x0
 8d4:	b7e080e7          	jalr	-1154(ra) # 44e <sbrk>
  if(p == (char*)-1)
 8d8:	fd5518e3          	bne	a0,s5,8a8 <malloc+0xac>
        return 0;
 8dc:	4501                	li	a0,0
 8de:	bf45                	j	88e <malloc+0x92>
