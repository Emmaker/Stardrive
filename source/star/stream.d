module star.stream;

import std.exception;
import std.conv;
import std.string;
import std.stdio;
import std.format;

interface ReadableStream
{
    void readBytes(ubyte[] bytes);

    void read(T)(T[] buf)
    {
        auto bytes = cast(ubyte*) buf;
        readBytes(bytes[0 .. T.sizeof * buf.length]);
    }
}

interface WritableStream
{
    void writeBytes(ubyte[] bytes);

    void write(T)(T[] buf)
    {
        auto bytes = cast(ubyte*) buf;
        writeBytes(bytes[0 .. T.sizeof * buf.length]);
    }
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
    private File* file;
    private ulong index;

    this(const string path)
    {
        this(new File(path, "rw"));
    }

    this(File* file)
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

    void readBytes(ubyte[] bytes)
    {
        auto read = file.rawRead!ubyte(bytes);
        index += read.length;
    }

    void writeBytes(ubyte[] bytes)
    {
        file.rawWrite!ubyte(bytes);
        index += bytes.length;
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
