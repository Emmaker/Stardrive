/** 
"Starbound Binary Object Notation"

SBON is the binary equivalent of JSON Starbound uses for almost every on-disk
format not meant for human readability.

The name was originally coined by the py-starbound library:
https://github.com/blixt/py-starbound/blob/master/FORMATS.md#sbon
 */
module star.sbon;

import std.file;
import std.exception;
import star.vlq;

enum SBONType : byte
{
    null_ = 1,
    double_ = 2,
    bool_ = 3,
    varint = 4,
    string = 5,
    list = 6,
    map = 7
}

alias SBONList = SBONValue[];
alias SBONMap = SBONValue[string];

struct SBONValue
{
    union Store
    {
        double double_;
        bool bool_;
        long varint;
        string str;
        SBONList list;
        SBONMap map;
    }

    private SBONType typeTag = SBONType.null_;
    private Store store;

    this(double double_)
    {
        this.typeTag = SBONType.double_;
        this.Store.double_ = double_;
    }

    this(bool bool_)
    {
        this.typeTag = SBONType.bool_;
        this.Store.bool_ = bool_;
    }

    this(long varint)
    {
        this.typeTag = SBONType.varint;
        this.Store.varint = varint;
    }

    this(string str)
    {
        this.typeTag = SBONType.string;
        this.Store.str = str;
    }

    this(SBONList list)
    {
        this.typeTag = SBONType.list;
        this.Store.list = list;
    }

    this(SBONMap map)
    {
        this.typeTag = SBONType.map;
        this.Store.map = map;
    }

    @property SBONType type() const pure nothrow @safe @nogc
    {
        return this.typeTag;
    }

    @property double double_() const pure @trusted return scope
    {
        enforce!Exception(typeTag == SBONType.double_,
            "SBONValue is not a double");
        return store.double_;
    }

    @property bool bool_() const pure @trusted return scope
    {
        enforce!Exception(typeTag == SBONType.bool_,
            "SBONValue is not a bool");
        return store.bool_;
    }

    @property long varint() const pure @trusted return scope
    {
        enforce!Exception(typeTag == SBONType.varint,
            "SBONValue is not a varint");
        return store.varint;
    }

    @property string str() const pure @trusted return scope
    {
        enforce!Exception(typeTag == SBONType.string,
            "SBONValue is not a string");
        return store.str;
    }

    @property SBONList list() const pure @trusted return scope
    {
        enforce!Exception(typeTag == SBONType.list,
            "SBONValue is not a list");
        return store.list;
    }

    @property SBONMap map() const pure @trusted return scope
    {
        enforce!Exception(typeTag == SBONType.map,
            "SBONValue is not a map");
        return store.map;
    }
}

SBONValue parseSBON(string sbon)
{
    int index = 0;
    return parseSBON(sbon, index);
}

SBONValue parseSBON(string sbon, ref int index)
{
    static byte[] readBytes(int size)
    {
        byte[] ret = sbon[index .. index + size];
        index += size;
        return ret;
    }

    static ulong readVLQ()
    {
        ubyte[] varBytes;
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
        string str;
        char c = 0;
        do
        {
            str ~= [(c = readBytes(1))];
        }
        while (c != '\0');
        return str;
    }

    byte type = readBytes(1);
    switch (type)
    {
    case SBONType.null_:
        return new SBONValue();

    case SBONType.double_:
        return new SBONValue(*cast(double*)&readBytes(double.sizeof));

    case SBONType.bool_:
        return new SBONValue(cast(bool) readBytes(1)[0]);

    case SBONType.varint:
        return new SBONValue(readVLQ());

    case SBONType.string:
        return SBONValue(readString());

    case SBONType.list:
        ulong count = readVLQ();
        auto list = new SBONValue[count];

        for (int i = 0; i < count; i++)
        {
            list[i] = parseSBON(sbon, index);
        }
        return new SBONValue(list);

    case SBONType.map:
        ulong count = readVLQ();
        auto map = new SBONMap[count];

        for (int i = 0; i < count; i++)
        {
            map[readString()] = parseSBON(sbon, index);
        }
        return new SBONValue(map);

    default:
        continue;
    }

    assert(0, format("Unrecognized type: %x", type));
}

string toSBON(ref const SBONValue root)
{
    string ret;
    ret ~= root.type;

    switch (root.type)
    {
    case SBONType.null_:
        break;

    case SBONType.double_:
        ret ~= root.double_();
        break;

    case SBONType.bool_:
        ret ~= root.bool_() ? cast(char) 1 : '\0';
        break;

    case SBONType.varint:
        ret ~= cast(char[]) encodeVLQ(root.value);
        break;

    case SBONType.string:
        ret ~= root.str();
        break;

    case SBONType.list:
        auto list = root.list();
        for (int i = 0; i < list.length; i++)
            ret ~= toSBON(list[i]);
        break;

    case SBONType.map:
        auto map = root.map();
        foreach (string key; map)
            ret ~= key ~= toSBON(map[key]);
        break;

    default:
        assert(0, format("Unrecognized type: %x", root.type));
    }

    return ret;
}
