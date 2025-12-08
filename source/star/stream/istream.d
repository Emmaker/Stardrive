/*
 * Interfaces and abstractions for streaming data between functions.
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
module star.stream.interfaces;

interface IReadableStream
{
    void readBytes(ubyte[] bytes);

    void read(T)(T[] buf)
    {
        auto bytes = cast(ubyte*) buf;
        readBytes(bytes[0 .. T.sizeof *buf.length]);
    }
}

interface IWritableStream
{
    void writeBytes(ubyte[] bytes);

    void write(T)(T[] buf)
    {
        auto bytes = cast(ubyte*) buf;
        writeBytes(bytes[0 .. T.sizeof *buf.length]);
    }
}

interface ISeekableStream
{
    void seek(ulong position);
    @property ulong pos();

    void opBinary(string op : ">>")(const int offset)
    {
        seek(pos + offset);
    }

    void opBinary(string op : "<<")(const int offset)
    {
        seek(pos - offset);
    }
}
