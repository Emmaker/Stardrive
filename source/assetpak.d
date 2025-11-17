import std.getopt;
import std.stdio;
import std.file;
import star.sbon;
import star.pak;
import star.stream;
import std.conv;
import core.stdc.stdlib;
import std.format;

int main(string[] args)
{
    bool verbose = false;
    bool extract = false;
    bool archive = false;
    bool force = false;
    string outOpt = null;
    string inOpt = null;

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
            "o|out", "File/directory to output", &outOpt,
            config.required,
            "i|in", "File/directory to extract/package", &inOpt,
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
        if (!std.file.exists(inOpt))
            err(format("%s does not exist", inOpt));
        if (!std.file.isFile(inOpt))
            err(format("%s is not file", inOpt));

        if (std.file.exists(outOpt))
        {
            if (!force)
                err(format("%s already exists", outOpt));
            if (!std.file.isDir(outOpt))
                err(format("%s is not a directory", outOpt));
        }

        auto fstream = new FileStream(inOpt);
    }
    else if (archive)
    {
        if (!std.file.exists(inOpt))
            err(format("%s does not exist", inOpt));
        if (!std.file.isDir(inOpt))
            err(format("%s is not a directory", inOpt));
    }
    else
    {
        err("Option extract or archive is required\nUse --help to get usage info");
        return 1;
    }

    return 0;
}
