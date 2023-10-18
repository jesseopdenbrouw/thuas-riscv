/*
 * syscalls.h -- system calls for the THUAS RISCV processor
 */


#ifndef _SYSCALLS_H
#define _SYSCALLS_H


#include <errno.h>
#include <stdio.h>
#include <signal.h>
#include <time.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/times.h>

#ifdef __cplusplus
extern "C" {
#endif

/* These are system call prototypes. */

void _exit(int status);

int _read(int fd, char *buf, int n);

int _write(int fd, char* buf, int n);

int _getpid(void);

int _kill(int pid, int sig);

int _close(int file);

int _fstat(int file, struct stat *st);

int _isatty(int file);

int _lseek(int file, int ptr, int dir);

int _open(char *path, int flags, ...);

int _wait(int *status);

int _unlink(char *name);

int _times(struct tms *buf);

int _stat(char *file, struct stat *st);

int _link(char *oldname, char *newname);

int _fork(void);

int _execve(char *name, char **argv, char **env);

void *_sbrk(ptrdiff_t incr);

#ifdef __cplusplus
}
#endif

#endif
