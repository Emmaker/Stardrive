#include <fcntl.h>
#include <unistd.h>
#include <stdbool.h>

enum _FDMode { R = 0, W = 1, RW = 2 };

unsigned long posix_open(char *path, int mode) {
  unsigned long fd;
  fd = 0;

  switch (mode) {
  case R:
    fd = open(path, O_RDONLY | O_CREAT,
              S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH);
    fd = fd == -1 ? 0 : fd;
    break;
  case W:
    fd = open(path, O_WRONLY | O_CREAT,
              S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH);
    fd = fd == -1 ? 0 : fd;
    break;
  case RW:
    fd = open(path, O_RDWR | O_CREAT,
              S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH);
    fd = fd == -1 ? 0 : fd;
    break;
  }
  return fd;
}

void posix_close(unsigned long fd) { close(fd); }

unsigned long posix_read(unsigned long fd, char *buf, unsigned long len) {
  int ret;

  ret = read(fd, buf, len);
  return ret == -1 ? 0 : ret;
}

unsigned long posix_write(unsigned long fd, char *buf, unsigned long len) {
  int ret;

  ret = write(fd, buf, len);
  return ret == -1 ? 0 : ret;
}

unsigned long posix_seek(unsigned long fd, unsigned long pos) {
    int ret;

    ret = lseek(fd, pos, SEEK_SET);
    return ret == -1 ? 0: ret;
}

bool posix_rewind(unsigned long fd) {
    int ret;

    ret = lseek(fd, 0, SEEK_SET);
    return ret != -1;
}

unsigned long posix_tell(unsigned long fd) {
    int ret;

    ret = lseek(fd, 0, SEEK_CUR);
    return ret == -1 ? 0 : ret;
}

int posix_begin(unsigned long fd) {
    int ret;

    ret = lseek(fd, 0, SEEK_CUR);
    if (ret == -1)
        return 2;

    return (ret == 0);
}

int posix_eof(unsigned long fd) {
    int ret;
    int pos;

    ret = lseek(fd, 0, SEEK_CUR);
    if (ret == -1)
        return 2;

    pos = lseek(fd, 0, SEEK_END);
    if (pos == -1)
        return 2;

    if (lseek(fd, ret, SEEK_SET) == -1)
        return 2;

    return (ret == pos);
}

unsigned long posix_duplicate(unsigned long fd) {
    int ret;

    ret = dup(fd);
    return ret == -1 ? 0 : ret;
}