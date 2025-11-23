module star.stream;

import std.exception;
import std.conv;
import std.string;
import std.stdio;

interface ReadableStream
{
    ubyte[] read(ulong length);
    // T[] rawRead(T)(T[] buf);
}

interface WritableStream
{
    void write(ubyte[] bytes);
    // void rawWrite(T)(T[] buf);
}

interface SeekableStream
{
    void seek(ulong position);
    @property ulong pos();

    void opBinary(string op : ">>")(const int offset)
    {
        seek(pos + offset);
    }

    void opBinary(string op : "<<")(const int offset)
    {
        seek(pos - offset);
    }
}

final class FileStream : ReadableStream, WritableStream, SeekableStream
{
    private File *file;
    private ulong index;

    this(const string path)
    {
        this(new File(path, "rw"));
    }

    this (File *file)
    {
        this.file = file;
        index = file.tell();
    }

    ~this()
    {
        file.detach();
    }

    void close()
    {
        file.close();
    }

    ubyte[] read(ulong len)
    {
        ubyte[] buf = new ubyte[len];
        index += len;
        file.rawRead!ubyte(buf);

        return buf;
    }

    T[] rawRead(T)(T[] buf)
    {
        auto slice = file.rawRead!T(buf);
        index += slice.length;
        return slice;
    }

    void write(ubyte[] bytes)
    {
        file.rawWrite!ubyte(bytes);
        index += bytes.length;
    }

    void rawWrite(T)(T[] buf)
    {
        auto slice = file.rawWrite!T(buf);
        index += slice.length;
    }

    void seek(ulong pos)
    {
        file.seek(pos, SEEK_SET);
        index = file.tell();
    }

    @property ulong pos()
    {
        return index;
    }
}

final class StringStream : ReadableStream, SeekableStream
{
    private const string str;
    private ulong index;

    this(const string str)
    {
        index = 0;
        this.str = str;
    }

    ubyte[] read(ulong len)
    {
        ubyte[] ret = cast(ubyte[]) str[index .. index + len].dup;
        index += len;
        return ret;
    }

    void seek(ulong pos)
    {
        index = (pos) < str.length ? pos : str.length;
    }

    @property ulong pos()
    {
        return index;
    }
}

final class StringBuilderStream : WritableStream
{
    private char[] builder;

    void write(ubyte[] bytes)
    {
        ulong length = builder.length;
        builder ~= cast(char[]) bytes;
    }

    string finalize()
    {
        return cast(string) builder;
    }
}
