module posix.fd;

struct FD
{
private:
    /*
     * An unsigned long should be large enough to store anything, whether
     * a number like UNIX file descriptors or a pointer to an object like
     * on Windows.
     */
    ulong fd = 0;
    Mode mode;

    // platform-dependent system wrappers written in C in another file
    @system
    {
        /**
         * Opens the file at the specified path, with the appropriate mode.
         * 
         *@param path NULL-terminated path to the file
         *@param mode The (enum) Mode of the file descriptor
         *@return The file descriptor, or 0 if error
         */
        extern (C) ulong posix_open(char* path, int mode);
        /**
         * Close the file descriptor.
         *
         *@param fd The file descriptor to close
         */
        extern (C) void posix_close(ulong fd);
        extern (C) ulong posix_read(ulong fd, char* buf, ulong len);
        extern (C) ulong posix_write(ulong fd, char* buf, ulong len);
        extern (C) ulong posix_seek(ulong fd, ulong pos);
        /**
         * Sets the file pointer to the beginning of the file (0).
         *
         *@param fd The file descriptor to rewind
         *@return Whether the rewind was succesful
         */
        extern (C) bool posix_rewind(ulong fd);
        extern (C) ulong posix_tell(ulong fd);
        /**
         * Tests if the file pointer is at the beginning of the file (0).
         *
         *@param fd The file descriptor to test
         *@return 0 if pointer is not at beginning, 1 if pointer is at beginning, 2 if operation failed
         */
        extern (C) int posix_begin(ulong fd);
        /**
         * Tests if the file pointer is at the end of the file.
         *
         *@param fd The file descriptor to test
         *@return 0 if pointer is not at EOF, 1 if pointer is at EOF, 2 if operation failed
         */
        extern (C) int posix_eof(ulong fd);
        extern (C) ulong posix_duplicate(ulong fd);
    }

public:
    enum Mode
    {
        R = 0,
        W = 1,
        RW = 2
    }

    @property bool open() pure
    {
        return fd != 0;
    }
}
