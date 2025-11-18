module star.stream;

import std.exception;
import std.conv;
import std.string;
import core.stdc.stdio;

interface ReadableStream
{
    ubyte[] read(scope ulong length);
}

string readStringz(ReadableStream stream)
{
    char[] carr;
    char c;
    while ((c = stream.read(1)[0]) != '\0')
        carr ~= c;
    return text(carr);
}

interface WritableStream
{
    ulong write(scope ubyte[] bytes);
}

void writeStringz(WritableStream stream, string str)
{
    ubyte[] carr = cast(ubyte[]) str.dup;
    carr ~= "\0";
    stream.write(carr);
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

        enforce!Exception(cast(ulong) open != ulong(0),
            format("Could not open file at %s", path));

        this.file = open;
    }

    ~this()
    {
        fclose(file);
    }

    ubyte[] read(scope ulong len)
    {
        ubyte[] buf;
        buf.reserve(len);

        ulong diff = fread(buf.ptr, 1, len, file);
        this.index += diff;

        return buf[0 .. (len - diff)];
    }

    ulong write(scope ubyte[] bytes)
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
    private const string str;
    private ulong index;

    this(const string str)
    {
        index = 0;
        this.str = str;
    }

    ubyte[] read(scope ulong len)
    {
        ubyte[] ret = cast(ubyte[]) str[index .. index + len].dup;
        index += len;
        return ret;
    }

    ulong seek(scope ulong pos)
    {
        index = (pos) < str.length ? pos : str.length;
        return index;
    }

    @property ulong pos()
    {
        return index;
    }
}

final class StringBuilderStream : WritableStream
{
    private char[] builder;

    ulong write(scope ubyte[] bytes)
    {
        ulong length = builder.length;
        builder ~= cast(char[]) bytes;
        return builder.length - length;
    }
}
