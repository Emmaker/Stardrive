#include <fcntl.h>
#include <stdbool.h>
#include <unistd.h>

#include "fdmode.c"

bool posix_open(char *path, int mode, unsigned long *fd) {
  unsigned long out;

  switch (mode) {
  case R:
    out = open(path, O_RDONLY | O_CREAT,
               S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH);
    break;
  case W:
    out = open(path, O_WRONLY | O_CREAT,
               S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH);
    break;
  case RW:
    out = open(path, O_RDWR | O_CREAT,
               S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH);
    break;
  }
  if (out == -1)
    return false;

  *fd = out;
  return true;
}

void posix_close(unsigned long fd) { close(fd); }

bool posix_read(unsigned long fd, char *buf, unsigned long *len) {
  int ret;
  ret = read(fd, buf, *len);

  if (ret == -1)
    return false;

  *len = ret;
  return true;
}

bool posix_write(unsigned long fd, char *buf, unsigned long *len) {
  int ret;
  ret = write(fd, buf, *len);

  if (ret == -1)
    return false;

  *len = ret;
  return true;
}

bool posix_seek(unsigned long fd, unsigned long *pos) {
  int ret;
  ret = lseek(fd, *pos, SEEK_SET);

  if (ret == -1)
    return false;

  *pos = ret;
  return true;
}

bool posix_tell(unsigned long fd, unsigned long *pos) {
  int ret;
  ret = lseek(fd, 0, SEEK_CUR);

  if (ret == -1)
    return false;

  *pos = ret;
  return true;
}

bool posix_duplicate(unsigned long fd, unsigned long *fd2) {
  int ret;
  ret = dup(fd);

  if (ret == -1)
    return false;

  *fd2 = ret;
  return false;
}