module star.sbasset;

import std.exception;
import std.bitmanip;

import star.stream;
import star.sbon;
import star.vlq;

class SBAsset6
{
    private SBONMap metaMap;

    struct AssetMeta
    {
        ulong size;
        ulong offset;

        this(ulong size, ulong offset)
        {
            this.size = size;
            this.offset = offset;
        }
    }

    private char[] stringBlock;
    private AssetMeta[string] assets;

    static SBAsset6 loadFromStream(T)(T stream)
            if (is(T : ReadableStream) && is(T : SeekableStream))
    {
        static const string magic = "SBAsset6";
        static const string metamagic = "INDEX";

        string rmagic = cast(string) stream.read(magic.length);
        enforce!Exception(rmagic == magic, "Invalid magic");

        ulong metaoff = *cast(ulong*) stream.read(ulong.sizeof).ptr;
        stream.seek(metaoff);

        string rmetamagic = cast(string) stream.read(metamagic.length);
        enforce!Exception(rmetamagic == metamagic, "Invalid metadata magic");

        auto pak = new SBAsset6();

        pak.metaMap = readSBONMap(stream);
        ulong count = decodeVLQ(stream);

        for (int i; i < count; i++)
        {
            string key = readStringz(stream);
            pak.stringBlock ~= cast(char[]) key; // we're not modifying key, so this is *safe*

            // By storing all keys in a contiguous block, it reduces the number of cache misses and therefore makes finding assets faster
            key = cast(string) stringBlock[$ - key.length .. $];
            ulong offset = littleEndianToNative!ulong(stream.read(ulong.sizeof));
            ulong size = littleEndianToNative!ulong(stream.read(ulong.sizeof));

            pak.assets[key] = AssetMeta(size, offset);
        }

        return pak;
    }
}
