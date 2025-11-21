module star.stream;

import std.exception;
import std.conv;
import std.string;
import std.stdio;

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
    private File file;
    private ulong index;

    this(const string path)
    {
        this.file = File(path, "rw");
        index = file.tell();
    }

    ~this()
    {
        file.close();
    }

    ubyte[] read(scope ulong len)
    {
        ubyte[] buf = new ubyte[len];
        buf = file.rawRead!ubyte(buf);

        return buf;
    }

    ulong write(scope ubyte[] bytes)
    {
        file.rawWrite!ubyte(bytes);
        return bytes.length;
    }

    ulong seek(scope ulong pos)
    {
        file.seek(pos, SEEK_SET);
        index = pos;
        return index;
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

    string finalize()
    {
        return cast(string) builder;
    }
}
