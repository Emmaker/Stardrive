module star.sbasset;

import std.exception;
import std.bitmanip;
import std.algorithm;
import std.range.interfaces;

import star.stream;
import star.sbon;
import star.vlq;

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

        static const string magic = "SBAsset6";
        static const string metaMagic = "INDEX";

        string rMagic = cast(string) stream.read(magic.length);
        enforce!Exception(rMagic == magic, "Invalid magic");

        ubyte[ulong.sizeof] metaBytes = stream.read(ulong.sizeof);
        ulong metaOff = bigEndianToNative!ulong(metaBytes);

        stream.seek(metaOff);

        string rMetaMagic = cast(string) stream.read(metaMagic.length);
        enforce!Exception(rMetaMagic == metaMagic, "Invalid metadata magic");

        metaMap = readSBONMap(stream);

        ulong count = decodeVLQ(stream);
        assetMap = new AssetMeta[count];
        // store for later streaming of strings
        ulong assetOff = stream.pos;

        ulong stringBlockSz = 0;
        for (int i = 0; i < count; i++)
        {
            ulong strLen = decodeVLQ(stream);
            stringBlockSz += strLen;
            stream >> cast(int) strLen;

            ubyte[ulong.sizeof] ul = stream.read(ulong.sizeof);
            assetMap[i].offset = bigEndianToNative!ulong(ul);
            ul = stream.read(ulong.sizeof);
            assetMap[i].size = bigEndianToNative!ulong(ul);
        }

        // allocate the string block
        stringBlock = new char[stringBlockSz];

        stream.seek(assetOff);
        ulong index = 0;
        for (int i = 0; i < count; i++)
        {
            ulong strLen = decodeVLQ(stream);
            auto slc = stringBlock[index .. index + strLen];
            stream.rawRead!char(slc);
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
            result = dg(i,
                stream.read(assetMap[i].size),
                cast(string) assetMap[i].name);
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
                return stream.read(assetMap[i].size);
            }
        throw new Exception("No asset with that name");
    }

    ubyte[] opIndex(ulong i)
    {
        stream.seek(assetMap[i].offset);
        return stream.read(assetMap[i].size);
    }
}
