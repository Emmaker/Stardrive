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
module star.stream.file;

import std.exception;
import std.conv;
import std.string;
import std.stdio;
import std.format;

import star.stream.istream;

final class FileStream : IReadableStream, IWritableStream, ISeekableStream
{
    private File* file;
    private ulong index;

    this(const string path)
    {
        this(new File(path, "rw"));
    }

    this(File* file)
    {
        this.file = file;
        index = file.tell();
    }

    ~this()
    {
        file.detach();
    }

    void close()
    {
        file.close();
    }

    void readBytes(ubyte[] bytes)
    {
        auto read = file.rawRead!ubyte(bytes);
        index += read.length;
    }

    void writeBytes(ubyte[] bytes)
    {
        file.rawWrite!ubyte(bytes);
        index += bytes.length;
    }

    void seek(ulong pos)
    {
        file.seek(pos, SEEK_SET);
        index = file.tell();
    }

    @property ulong pos()
    {
        return index;
    }
}
