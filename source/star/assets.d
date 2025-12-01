module star.assets;

import std.file;
import std.exception;
import std.bitmanip;

import star.stream;
import star.sbon;

interface AssetSource
{
    interface AssetStream : ReadableStream, WritableStream
    {
    }

    AssetStream open(string path);
    @property SBONMap metadata();
}

class SBAsset6 : AssetSource
{
private:
    FileStream stream;
    SBONMap meta;

    struct Asset
    {
        ulong size;
        ulong offset;
    }

    Asset[string] assets;

public:
    AssetStream open(string path)
    {
        return null;
    }

    @property SBONMap metadata()
    {
        return meta;
    }

    this(string path)
    {
        this(new FileStream(path));
    }

    this(FileStream stream)
    {
        this.stream = stream;

        if (!validateMagic(stream))
            throw new Exception("Magic does not match SBAsset6");

        ubyte[8] offsetBytes;
        stream.read(offsetBytes);
        ulong offset = bigEndianToNative!ulong(offsetBytes);

        stream.seek(offset);
        if (!validateIndexMagic(stream))
            throw new Exception("Index magic does not match INDEX");

        meta = readSBONMap(stream);

        ulong count = readVLQ(stream);

        // a little bit of magic to make the allocation and reading a bit faster
        struct NameHeap
        {
            char[] heap = new char[0];
            ulong off;

            string append(FileStream stream)
            {
                ulong len = readVLQ(stream);
                if (len > heap.length - off)
                    heap.reserve(heap.length * 2 > len ? heap.length * 2 : len);

                char[] stored = heap[off .. off += len];
                stream.read!char(stored);

                return cast(string) stored;
            }
        }

        NameHeap heap;
        do
        {
            string path = heap.append(stream);

            ubyte[ulong.sizeof] ul;
            stream.read(ul);
            assets[path].offset = bigEndianToNative!ulong(ul);
            stream.read(ul);
            assets[path].size = bigEndianToNative!ulong(ul);
        }
        while (--count);
    }

    static bool validateMagic(FileStream stream)
    {
        char[8] readMagic;
        stream.read!char(readMagic);

        return (readMagic == "SBAsset6");
    }

    static bool validateIndexMagic(FileStream stream)
    {
        char[5] readMagic;
        stream.read!char(readMagic);

        return (readMagic == "INDEX");
    }
}
