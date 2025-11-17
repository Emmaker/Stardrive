module star.stream;

import std.exception;
import std.string;
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
        FILE* open = fopen(toStringz(path), "rw\0");

        enforce!Exception(open != 0,
            format("Could not open file at %s", path));

        this.file = open;
    }

    ~this()
    {
        fclose(file);
    }

    byte[] read(scope ulong len)
    {
        byte[len] buf;

        ulong diff = fread(buf.ptr, 1, len, file);
        this.index += diff;

        return buf[0 .. (len - diff)];
    }

    ulong write(scope byte[] bytes)
    {
        size_t diff = fwrite(bytes.ptr, 1, bytes.length, file);
        this.index += diff;

        return diff;
    }

    ulong seek(scope ulong pos)
    {
        this.index = fseek(file, pos, SEEK_SET);
        return this.index;
    }

    @property ulong pos() const
    {
        return index;
    }
}

final class StringStream : ReadableStream, SeekableStream
{
    private const string *str;
    private ulong index;

    this (const string *str)
    {
        index = 0;
        this.str = str;
    }

    byte[] read(scope ulong len)
    {
        byte[] ret = str[index .. index + len];
        index += len;
        return ret;
    }

    ulong seek(scope ulong pos)
    {
        index = (pos) < str.length ? pos : str.length;
        return index;
    }
}

final class StringBuilderStream : WritableStream
{
    private char[] builder;

    ulong write(scope byte[] bytes)
    {
        ulong length = builder.length;
        builder ~= cast(char[]) bytes;
        return builder.length - length;
    }
}