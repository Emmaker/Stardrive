module star.sbon;

import std.exception;
import std.bitmanip;
import star.stream;
import star.vlq;

enum SBONType : byte
{
    nil = 1,
    dbl = 2,
    boolean = 3,
    number = 4,
    str = 5,
    list = 6,
    map = 7
}

alias SBONList = SBONValue[];
alias SBONMap = SBONValue[string];

struct SBONValue
{
    union Store
    {
        double dbl;
        bool boolean;
        ulong number;
        string str;
        SBONList list;
        SBONMap map;
    }

    private SBONType tag = SBONType.nil;
    private Store store;

    this(double dbl) pure nothrow
    {
        tag = SBONType.dbl;
        store.dbl = dbl;
    }

    this(bool boolean) pure nothrow
    {
        tag = SBONType.boolean;
        store.boolean = boolean;
    }

    this(ulong number) pure nothrow
    {
        tag = SBONType.number;
        store.number = number;
    }

    this(string str) pure nothrow
    {
        tag = SBONType.str;
        store.str = str;
    }

    this(SBONList list) pure nothrow
    {
        tag = SBONType.list;
        store.list = list;
    }

    this(SBONMap map) pure nothrow
    {
        tag = SBONType.map;
        store.map = map;
    }

    @property SBONType type() const pure nothrow
    {
        return tag;
    }

    @property double dbl() const pure
    {
        enforce!Exception(tag == SBONType.dbl,
            "SBONValue is not double");
        return store.dbl;
    }

    @property bool boolean() const pure
    {
        enforce!Exception(tag == SBONType.boolean,
            "SBONValue is not boolean");
        return store.boolean;
    }

    @property ulong number() const pure
    {
        enforce!Exception(tag == SBONType.number,
            "SBONValue is not number");
        return store.number;
    }

    @property string str() const pure
    {
        enforce!Exception(tag == SBONType.str,
            "SBONValue is not string");
        return store.str;
    }

    @property const(SBONList) list() const pure
    {
        enforce!Exception(tag == SBONType.list,
            "SBONValue is not list");
        return store.list;
    }

    @property const(SBONMap) map() const pure
    {
        enforce!Exception(tag == SBONType.map,
            "SBONValue is not map");
        return store.map;
    }
}

SBONValue* readSBON(ReadableStream stream)
{
    ubyte[1] tag;
    stream.readBytes(tag);
    switch (tag[0])
    {
    case SBONType.nil:
        return new SBONValue();
    case SBONType.dbl:
        ubyte[double.sizeof] bytes;
        stream.read(bytes);
        return new SBONValue(bigEndianToNative!double(bytes));
    case SBONType.boolean:
        ubyte[1] bytes;
        stream.read(bytes);
        return new SBONValue(bigEndianToNative!bool(bytes));
    case SBONType.number:
        return new SBONValue(decodeVLQ(stream));
    case SBONType.str:
        return new SBONValue(readSBONString(stream));
    case SBONType.list:
        return new SBONValue(readSBONList(stream));
    case SBONType.map:
        return new SBONValue(readSBONMap(stream));
    default:
        // fallthrough
    }
    assert(0, "Unrecognized SBON tag");
}

string readSBONString(ReadableStream stream)
{
    ulong length = decodeVLQ(stream);
    char[] carr = new char[length];
    stream.read(carr);
    return cast(string) carr;
}

SBONList readSBONList(ReadableStream stream)
{
    ulong count = decodeVLQ(stream);
    SBONList list;
    for (int i = 0; i < count; i++)
        list[i] = *readSBON(stream);
    return list;
}

SBONMap readSBONMap(ReadableStream stream)
{
    ulong count = decodeVLQ(stream);
    SBONMap map;
    for (int i = 0; i < count; i++)
        map[readSBONString(stream)] = *readSBON(stream);
    return map;
}

void writeSBON(WritableStream stream, const SBONValue* root)
{
    void writeTag()
    {
        stream.write(nativeToBigEndian(root.type));
    }

    switch (root.type)
    {
    case SBONType.nil:
        writeTag();
        return;
    case SBONType.dbl:
        writeTag();
        stream.write(nativeToBigEndian(root.dbl));
        return;
    case SBONType.boolean:
        writeTag();
        stream.write(nativeToBigEndian(root.boolean));
        return;
    case SBONType.number:
        writeTag();
        encodeVLQ(stream, root.number);
        return;
    case SBONType.str:
        writeTag();
        encodeVLQ(stream, root.str.length);
        stream.writeBytes(cast(ubyte[]) root.str);
        return;
    case SBONType.list:
        writeTag();
        writeSBONList(stream, root.list);
        return;
    case SBONType.map:
        writeTag();
        writeSBONMap(stream, root.map);
        return;
    default:
        // fallthrough
    }
    assert(0, "Unrecognized SBON tag");
}

void writeSBONList(WritableStream stream, const SBONList list)
{
    ulong length = list.length;
    encodeVLQ(stream, length);
    for (int i = 0; i < length; i++)
        writeSBON(stream, &list[i]);
}

void writeSBONMap(WritableStream stream, const SBONMap map)
{
    ulong length = map.length;
    encodeVLQ(stream, length);
    foreach (key; map.byKey)
    {
        encodeVLQ(stream, key.length);
        stream.writeBytes(cast(ubyte[]) key);
        writeSBON(stream, &map[key]);
    }
}
