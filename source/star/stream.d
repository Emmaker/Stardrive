module star.stream;

import core.stdc.stdio;

interface ReadableStream
{
    byte[] read(scope ulong length);
}

interface WritableStream
{
    ulong write(scope byte[] bytes);
}

interface SeekableStream
{
    ulong seek(scope ulong position);
    @property ulong pos();

    void opBinary(string op : ">>")(const int offset) const
    {
        seek(pos() + offset);
    }

    void opBinary(string op : "<<")(const int offset) const
    {
        seek(pos() - offset);
    }
}

final class FileStream : ReadableStream, WritableStream, SeekableStream
{
    private FILE* file;
    private ulong index;

    this(const string path)
    {
        index = 0;
        FILE* open = fopen(path, "rw\0");

        enforce!Exception(open != 0,
            format("Could not open file at %s", path));

        this.file = open;
    }

    override byte[] read(const ulong len)
    {
        byte[len] buf;

        ulong diff = fread(buf.ptr, 1, len, file);
        this.index += diff;

        return buf[0 .. (len - diff)];
    }

    override ulong write(const byte[] bytes)
    {
        size_t diff = fwrite(bytes.ptr, 1, bytes.length, file);
        this.index += diff;

        return diff;
    }

    override ulong seek(const size_t pos)
    {
        this.index = fseek(file, pos, SEEK_SET);
        return this.index;
    }

    override @property ulong pos() const
    {
        return index;
    }
}
