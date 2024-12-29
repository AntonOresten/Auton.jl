function tee_stdout(f::Function, mirror::IO)
    old_stdout = stdout
    rd, wr = redirect_stdout()
    relay_task = @async begin
        try
            while true
                chunk = readavailable(rd)
                if !isempty(chunk)
                    write(mirror, chunk)
                    write(old_stdout, chunk)
                    flush(old_stdout)
                elseif eof(rd)
                    break
                else
                    yield()
                end
            end
        catch e
            rethrow(e)
        end
    end
    try
        ret = f()
        flush(stdout)
        return ret
    finally
        close(wr)
        redirect_stdout(old_stdout)
        wait(relay_task)
    end
end

function tee_stdout(f::Function)
    mirror = IOBuffer()
    tee_stdout(mirror) do
        f()
    end
    return String(take!(mirror))
end

function tee_stdout_with_stderr(f::Function)
    err = IOBuffer()
    out = tee_stdout() do
        try
            f()
        catch e
            showerror(err, e)
            Base.show_backtrace(err, catch_backtrace())
        end
    end
    err_msg = String(take!(err))
    println(stdout, err_msg)
    return out, err_msg
end

# Base.display does not use stdout
function showdisplay(io::IO, x)
    show(IOContext(io, :limit=>true), MIME("text/plain"), x)
    println()
end

showdisplay(x) = showdisplay(stdout, x)


function format_block_line(
    prefix::AbstractString, content::AbstractString,
    prefix_color::Symbol=:blue, content_color::Symbol=:default,
)
    Base.text_colors[prefix_color] * "$prefix" * Base.text_colors[content_color] * content
end


abstract type IORule <: IO end

close_rule(::IO) = nothing
close_rule(io::IORule) = close_rule(io.parent)

Base.close(io::IORule) = close_rule(io)

struct Formatter <: IORule
    parent::IO
    formatter::Function
end

Formatter(f::Function, parent::IO) = Formatter(parent, f)

function Base.write(io::Formatter, data::Union{SubString{String}, String})
    write(io.parent, io.formatter(data))
end

Color(io::IO, color::Symbol) = Formatter(io, x -> Base.text_colors[color] * x)


struct Split <: IORule
    parent::IO
    split_func::Function
end

function Base.write(io::Split, str::Union{SubString{String}, String})
    for substr in io.split_func(str)
        write(io.parent, substr)
    end
end


split_line(s::AbstractString, n::Integer) = @views [s[i:min(i+n-1, end)] for i in 1:n:length(s)]

# TODO: smart word-aware line split

function LineSplit(io::IO, width::Integer=displaysize(stdout)[2] - 5)
    return Split(io, s -> map(x -> x * "\n", split_line(s, width)))
end


struct Block <: IORule
    parent::IO
    header::String
    color::Symbol

    function Block(parent::IO, header::String, color::Symbol=:green)
        block = new(parent, header, color)
        println(stdout, format_block_line("╭─$header", "", block.color))
        return block
    end
end

function Base.write(io::Block, str::Union{SubString{String}, String})
    print(stdout, format_block_line("│ ", "", io.color))
    write(io.parent, str)
end

function close_rule(io::Block)
    println(stdout, format_block_line("╰───┈─┈─┈┈┈ ┈ ┈", "", io.color))
end


struct Lines <: IORule
    parent::IO
    buffer::Vector{UInt8}
end

Lines(parent::IO=stdout) = Lines(parent, UInt8[])

function Base.write(io::Lines, str::Union{SubString{String}, String})
    push!(io.buffer, codeunits(str)...)
    while true
        last_newline_index = findfirst(x -> x == 0x0a, io.buffer)
        if last_newline_index === nothing
            break
        end
        to_flush = io.buffer[1:last_newline_index]
        write(io.parent, String(to_flush))
        deleteat!(io.buffer, 1:last_newline_index)
    end
    return nothing
end

function close_rule(io::Lines)
    write(io, "\n")
    close_rule(io.parent)
end

