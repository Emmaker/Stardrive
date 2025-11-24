module star.sbasset;

import std.exception;
import std.bitmanip;
import std.algorithm;
import std.range.interfaces;

import star.stream;
import star.sbon;

class SBAsset6
{
private:
    SBONMap metaMap;

    struct AssetMeta
    {
        char[] name;
        ulong size;
        ulong offset;
    }

    char[] stringBlock;
    AssetMeta[] assetMap;

    FileStream stream;

public:
    this(FileStream stream)
    {
        this.stream = stream;

        static const char[] magic = "SBAsset6";
        static const char[] metaMagic = "INDEX";

        char[magic.length] rMagic;
        stream.read!char(rMagic);
        enforce!Exception(rMagic == magic, "Invalid magic");

        ubyte[ulong.sizeof] metaBytes;
        stream.read(metaBytes);
        ulong metaOff = bigEndianToNative!ulong(metaBytes);

        stream.seek(metaOff);

        char[metaMagic.length] rMetaMagic;
        stream.read(rMetaMagic);
        enforce!Exception(rMetaMagic == metaMagic, "Invalid metadata magic");

        metaMap = readSBONMap(stream);

        ulong count = readVLQ(stream);
        assetMap = new AssetMeta[count];
        // store for later streaming of strings
        ulong assetOff = stream.pos;

        ulong stringBlockSz = 0;
        for (int i = 0; i < count; i++)
        {
            ulong strLen = readVLQ(stream);
            stringBlockSz += strLen;
            stream >> cast(int) strLen;

            ubyte[ulong.sizeof] ul;
            stream.read(ul);
            assetMap[i].offset = bigEndianToNative!ulong(ul);
            stream.read(ul);
            assetMap[i].size = bigEndianToNative!ulong(ul);
        }

        // allocate the string block
        stringBlock = new char[stringBlockSz];

        stream.seek(assetOff);
        ulong index = 0;
        for (int i = 0; i < count; i++)
        {
            ulong strLen = readVLQ(stream);
            auto slc = stringBlock[index .. index + strLen];
            stream.read!char(slc);
            index += strLen;

            assetMap[i].name = slc;
            stream >> (ulong.sizeof * 2);
        }
    }

    int opApply(scope int delegate(string) dg)
    {
        int result = 0;
        foreach (i; 0 .. assetMap.length)
        {
            result = dg(cast(string) assetMap[i].name);
            if (result)
                break;
        }
        return result;
    }

    int opApply(scope int delegate(ulong, string) dg)
    {
        int result = 0;
        foreach (i; 0 .. assetMap.length)
        {
            result = dg(i, cast(string) assetMap[i].name);
            if (result)
                break;
        }
        return result;
    }

    int opApply(scope int delegate(ulong, ubyte[], string) dg)
    {
        int result = 0;
        foreach (i; 0 .. assetMap.length)
        {
            stream.seek(assetMap[i].offset);
            auto bytes = new ubyte[assetMap[i].size];
            stream.read(bytes);

            result = dg(i, bytes, cast(string) assetMap[i].name);
            if (result)
                break;
        }
        return result;
    }

    ubyte[] opIndex(string name)
    {
        foreach (i, string mapName; this)
            if (name == mapName)
            {
                stream.seek(assetMap[i].offset);
                auto bytes = new ubyte[assetMap[i].size];
                stream.read(bytes);
                return bytes;
            }
        throw new Exception("No asset with that name");
    }

    ubyte[] opIndex(ulong i)
    {
        auto bytes = new ubyte[assetMap[i].size];
        stream.read(bytes);
        return bytes;
    }
}
