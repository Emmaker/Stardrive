/*
 * Reader and writer implementation for Starbound Object Notation (SBON).
 * Copyright (C) 2025 Emmaker
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
module star.sbon;

import std.exception;
import std.bitmanip;

import star.stream;

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

SBONValue* readSBON(IReadableStream stream)
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
        return new SBONValue(readVLQ(stream));
    case SBONType.str:
        return new SBONValue(readSBONString(stream));
    case SBONType.list:
        return new SBONValue(readSBONList(stream));
    case SBONType.map:
        return new SBONValue(readSBONMap(stream));
    default:
        // fallthrough
    }
    throw new Exception("Unrecognized SBON tag");
}

ulong readVLQ(IReadableStream stream)
{
    ulong result = 0;
    ubyte[1] v;
    do
    {
        stream.readBytes(v);

        result <<= 7;
        result |= v[0] & 0x7F;
    }
    while ((v[0] & 0x80) != 0);
    return result;
}

string readSBONString(IReadableStream stream)
{
    ulong length = readVLQ(stream);
    char[] carr = new char[length];
    stream.read(carr);
    return cast(string) carr;
}

SBONList readSBONList(IReadableStream stream)
{
    ulong count = readVLQ(stream);
    SBONList list;
    for (int i = 0; i < count; i++)
        list[i] = *readSBON(stream);
    return list;
}

SBONMap readSBONMap(IReadableStream stream)
{
    ulong count = readVLQ(stream);
    SBONMap map;
    for (int i = 0; i < count; i++)
        map[readSBONString(stream)] = *readSBON(stream);
    return map;
}

void writeSBON(IWritableStream stream, const SBONValue* root)
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
        writeVLQ(stream, root.number);
        return;
    case SBONType.str:
        writeTag();
        writeSBONString(stream, root.str);
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
    throw new Exception("Unrecognized SBON tag");
}

void writeVLQ(IWritableStream stream, const ulong val)
{
    ubyte[] result;
    ulong value = val;

    if (value == 0)
    {
        result ~= 0;
        goto write;
    }

    while (value > 0)
    {
        ubyte byteVal = value & 0x7F;
        value >>= 7;
        if (value != 0)
            byteVal |= 0x80;
        result ~= byteVal;
    }
write:
    stream.writeBytes(result);
}

void writeSBONString(IWritableStream stream, const string str)
{
    writeVLQ(stream, str.length);
    // this is okay because we're not modifying the immutable type
    stream.writeBytes(cast(ubyte[]) str);
}

void writeSBONList(IWritableStream stream, const SBONList list)
{
    ulong length = list.length;
    writeVLQ(stream, length);
    for (int i = 0; i < length; i++)
        writeSBON(stream, &list[i]);
}

void writeSBONMap(IWritableStream stream, const SBONMap map)
{
    ulong length = map.length;
    writeVLQ(stream, length);
    foreach (key; map.byKey)
    {
        writeVLQ(stream, key.length);
        stream.writeBytes(cast(ubyte[]) key);
        writeSBON(stream, &map[key]);
    }
}
