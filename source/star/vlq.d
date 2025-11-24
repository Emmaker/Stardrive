module star.vlq;

import std.stdio;
import std.range;
import std.array;
import std.conv;

import star.stream;

/**
 * Encodes an integer into a variable-length quantity (VLQ) byte array.
 *
 * @param value The integer to encode.
 * @return A byte array representing the VLQ-encoded integer.
 */
ubyte[] encodeVLQ(ulong value)
{
    ubyte[] result;
    if (value == 0)
    {
        result ~= 0;
        return result;
    }

    while (value > 0)
    {
        ubyte byteVal = value & 0x7F;
        value >>= 7;
        if (value != 0)
        {
            byteVal |= 0x80;
        }
        result ~= byteVal;
    }
    return result;
}

void encodeVLQ(ref WritableStream stream, ulong value)
{
    ubyte[] bytes = encodeVLQ(value);
    stream.write(bytes);
}

/**
 * Decodes a variable-length quantity (VLQ) byte array into an integer.
 *
 * @param bytes The byte array to decode.
 * @return The decoded integer.
 */
ulong decodeVLQ(ubyte[] bytes)
{
    ulong result = 0;
    foreach (byteVal; bytes)
    {
        result <<= 7;
        result |= byteVal & 0x7F;

        if ((byteVal & 0x80) == 0)
        {
            break;
        }
    }
    return result;
}

ulong decodeVLQ(ReadableStream stream)
{
    ubyte[] vlq;
    ubyte[1] v;
    do
    {
        stream.read(v);
        vlq ~= v;
    }
    while (v[0] & 0x80);
    return decodeVLQ(vlq);
}
