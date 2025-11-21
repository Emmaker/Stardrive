module star.sbasset;

import std.exception;

import star.stream;

class SBAsset6
{
    static SBAsset6 loadFromFile(string file)
    {
        return loadFromFile(new FileStream(file));
    }

    static SBAsset6 loadFromFile(FileStream stream)
    {
        if (stream.pos != 0)
            stream.seek(0);

        static const string magic = "SBAsset6";
        static const string metamagic = "INDEX";

        string rmagic = cast(string) stream.read(magic.length);
        enforce!Exception(rmagic == magic, "Invalid magic");

        ulong metaoff = *cast(ulong*) stream.read(ulong.sizeof).ptr;
        stream.seek(metaoff);

        string rmetamagic = cast(string) stream.read(metamagic.length);
        enforce!Exception(rmetamagic == metamagic, "Invalid metadata magic");

        return new SBAsset6();
    }
}
