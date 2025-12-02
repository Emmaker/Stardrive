module posix.fd;

import std.exception;
import std.format;

import posix.fdmode;

struct FD
{
private:
    /*
     * An unsigned long should be large enough to store anything, whether
     * a number like UNIX file descriptors or a pointer to an object like
     * on Windows.
     */
    ulong fd = 0;
    FDMode mode;

    // platform-dependent system wrappers written in C in another file
    @system
    {
        /** 
         * Opens the file at the specified path.
         * Creates the file if it does not exist, with system-specific defaults.
         *
         *@param path The path of the file to open
         *@param mode The mode to open the file in
         *@param fd The descriptor of the opened file
         *@return Whether the operation was successful
         */
        extern (C) bool posix_open(char* path, int mode, ref ulong fd);
        /** 
         * Close the specified file descriptor.
         *
         *@param fd The file descriptor to close
         */
        extern (C) void posix_close(ulong fd);
        /** 
         * Read from an open file descriptor.
         * The len parameter is used both when reading, and is set to how many bytes were read.
         *
         *@param fd The file descriptor to read from
         *@param buf The memory to read into
         *@param len The number of bytes to read
         *@return Whether the operation was successful
         */
        extern (C) bool posix_read(ulong fd, char* buf, ref ulong len);
        /** 
         * Write an open file descriptor.
         * The len parameter is used both when writing, and is set to how many bytes were written.
         *
         *@param fd The file descriptor to write to
         *@param buf The memory to write from
         *@param len The number of bytes to write
         *@return Whether the operation was successful
         */
        extern (C) bool posix_write(ulong fd, char* buf, ref ulong len);
        /**
         * Move the pointer of a file descriptor.
         * The pos parameter is used both to set, and is set to the new position
         *
         *@param fd The file descriptor to move the pointer of
         *@param pos The position to set the pointer to
         *@return Whether the operation was successful
         */
        extern (C) bool posix_seek(ulong fd, ref ulong pos);
        /**
         * Tells the position of the pointer of a file descriptor.
         *
         *@param fd The file descriptor to tell
         *@param pos The position of the FD's pointer
         *@return Whether the operation was successful
         */
        extern (C) bool posix_tell(ulong fd, ref ulong pos);
        /**
         * Duplicate a file descriptor, creating a new FD that describes the same file.
         *
         *@param fd The file descriptor to duplicate
         *@param fd2 The file descriptor that was duplicated
         *@return Whether the operation was successful
         */
        extern (C) bool posix_duplicate(ulong fd, ref ulong fd2);
    }

    this(ulong fd, FDMode mode)
    {
        this.fd = fd;
        this.mode = mode;
    }

public:
    @trusted @property bool open() pure
    {
        return fd != 0;
    }

    @trusted this(string path, FDMode mode)
    {
        char[] stringz = new char[path.length + 1];
        // copy the string to the new allocation
        stringz[] = path[];
        // null terminate
        stringz[path.length] = 0;

        this.mode = mode;
        auto ret = posix_open(stringz.ptr, mode, this.fd);
        enforce!Exception(ret, "Failed to open file descriptor");
    }

    // transfering ownership must be done with explicit move mutations
    @disable this(this);

    @trusted void close()
    {
        enforce!Exception(open, "File descriptor is not open");

        posix_close(fd);
        fd = 0;
    }

    @trusted void duplicate(ref FD fd2)
    {
        enforce!Exception(open, "File descriptor is not open");

        auto ret = posix_duplicate(fd, fd2.fd);
        enforce!Exception(ret, "Failed to duplicate file descriptor");
        fd2.mode = this.mode;
    }

    @trusted ulong tell()
    {
        enforce!Exception(open, "File descriptor is not open");

        ulong pos;
        auto ret = posix_tell(fd, pos);
        enforce!Exception(ret, "Failed to tell file descriptor");
        return pos;
    }

    @trusted @property ulong pos()
    {
        return tell();
    }

    @trusted void seek(ulong pos)
    {
        enforce!Exception(open, "File descriptor is not open");

        ulong _pos = pos;
        auto ret = posix_seek(fd, _pos);
        enforce!Exception(ret, "Failed to seek file descriptor");

        enforce!Exception(_pos == pos, format("File is smaller than %x", pos));
    }

    @trusted @property void pos(ulong npos)
    {
        seek(npos);
    }

    @trusted void read(T)(T[] buf)
    {
        enforce!Exception(open, "File descriptor is not open");

        enforce!Exception((mode == FDMode.R) | (mode == FDMode.RW),
            "File descriptor mode does not support reading");

        ulong bytes = T.sizeof * buf.length;
        auto ret = posix_read(fd, cast(char*) buf.ptr, bytes);
        enforce!Exception(ret, "Failed to read from file descriptor");

        enforce!Exception(bytes == T.sizeof * buf.length,
            "Could not read all bytes from file");
    }

    @trusted void write(T)(T[] buf)
    {
        enforce!Exception(open, "File descriptor is not open");

        enforce!Exception((mode == FDMode.W) | (mode == FDMode.RW),
            "File descriptor mode does not support writing");

        ulong bytes = T.sizeof * buf.length;
        auto ret = posix_write(fd, cast(char*) buf.ptr, bytes);
        enforce!Exception(ret, "Failed to write to file descriptor");

        enforce!Exception(bytes == T.sizeof * buf.length,
            "Could not write all bytes to file");
    }
}
