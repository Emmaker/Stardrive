/*
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
import std.getopt;
import std.stdio;
import std.file;
import std.conv;
import std.path;
import std.format;
import core.stdc.stdlib;

import star.sbon;
import star.stream;
import star.sbasset;

int main(string[] args)
{
    bool verbose = false;
    bool extract = false;
    bool archive = false;
    bool force = false;
    string output = null;
    string input = null;

    static noreturn err(string str)
    {
        stderr.writeln(str);
        core.stdc.stdlib.exit(1);
    }

    GetoptResult opts;
    try
    {
        opts = getopt(
            args, config.caseSensitive,
            "v|verbose", "Print additional info to console", &verbose,
            "extract", "Extract files from a .pak archive", &extract,
            "package", "Package files into a .pak archive", &archive,
            "f|force", "Ignore minor errors", &force,
            config.required,
            "o|out", "File/directory to output", &output,
            config.required,
            "i|in", "File/directory to extract/package", &input,
        );
    }
    catch (std.conv.ConvException e)
    {
        err(e.msg);
    }
    catch (std.getopt.GetOptException e)
    {
        err(e.msg);
    }

    auto inPath = absolutePath(input);
    auto outPath = absolutePath(output);

    if (opts.helpWanted)
    {
        defaultGetoptPrinter("Pack or unpack Starbound assets into a .pak archive\n", opts.options);
        return 0;
    }

    if (extract && archive)
    {
        err("Options extract and archive are mutually exclusive");
        return 1;
    }
    else if (extract)
    {
        if (!std.file.exists(inPath))
            err(format("%s does not exist", input));
        if (!std.file.isFile(inPath))
            err(format("%s is not file", input));

        if (!std.file.exists(outPath))
            err(format("%s does not exist", outPath));
        if (!std.file.isDir(outPath))
            err(format("%s is not a directory", output));

        auto stream = new FileStream(inPath);
        auto pak = new SBAsset6(stream);

        foreach (i, bytes, asset; pak)
        {
            char[] exPath = cast(char[]) outPath.dup;
            exPath ~= cast(char[]) asset;

            if (std.file.exists(exPath) && !std.file.isFile(exPath))
                err(format("%s is not a file", exPath));
            mkdirRecurse(dirName(exPath));

            auto ex = new FileStream(new File(exPath, "w"));
            ex.seek(0);
            ex.write(bytes);
            ex.close();
        }
    }
    else if (archive)
    {
        if (!std.file.exists(inPath))
            err(format("%s does not exist", input));
        if (!std.file.isDir(inPath))
            err(format("%s is not a directory", input));
    }
    else
    {
        err("Option extract or archive is required");
        return 1;
    }

    return 0;
}
