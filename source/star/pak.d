module star.pak;

import star.sbon;

struct PAKHeader
{
    const char[8] magic = "SBAsset6";
    ulong metaOffset;
}

struct PAKMeta
{
    const char[5] magic = "INDEX";
    SBONMap info;

    struct File
    {
        string name;
        ulong offset;
        ulong size;
    }

    File[] files;
}

PAKHeader parsePAKHeader(char[16] str)
{
    enforce!Exception(str[0 .. 8] == PAKHEader.magic,
        "Header magic is not valid");

    auto header = new PAKHeader();
    header.metaOffset = *cast(ulong*)&str[9 .. 16];

    return header;
}

PAKMeta parsePAKMeta(string str)
{
    int index = 0;

    static byte[] readBytes(int size)
    {
        byte[] ret = str[index .. index + size];
        index += size;
        return ret;
    }

    static ulong readVLQ()
    {
        ubyte[] varBytes = new ubyte[];
        ubyte varByte;
        do
        {
            varBytes ~= [(varByte = readBytes(1))];
        }
        while (varByte & 0x80);
        return decodeVLQ(varBytes);
    }

    static string readString()
    {
        string str = new string();
        char c = 0;
        do
        {
            str ~= [(c = readBytes(1))];
        }
        while (c != '\0');
        return str;
    }

    enforce!Exception(readBytes(5) == PAKMeta.magic,
        "Meta magic is not valid");

    auto meta = new PAKMeta();

    auto info = parseSBON(str, index);
    enforce!Exception(info.type == SBONType.map,
        "Meta info field is not map");
    meta.info = info;

    auto files = new PAKMeta.File[readVLQ()];
    for (int i = 0; i < files.count; i++)
    {
        auto ref file = files[i];
        file.name = readString();
        file.offset = *cast(ulong*)&readBytes(8);
        file.size = *cast(ulong*)&readBytes(8);
    }

    return meta;
}

string toPAKHeader(PAKHeader header)
{
    string str;
    str ~= header.magic;
    str ~= header.metaOffset;
    return str;
}

string toPAKMeta(PAKMeta meta)
{
    string str;

    return str;
}