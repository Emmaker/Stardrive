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

        if (std.file.exists(output))
        {
            if (!force)
                err(format("%s already exists", output));
            if (!std.file.isDir(outPath))
                err(format("%s is not a directory", output));
        }

        SBAsset6 pak = SBAsset6.loadFromFile(inPath);
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
