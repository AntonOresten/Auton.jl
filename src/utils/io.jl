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


abstract type IORule end

struct IOWithRule{Rule<:IORule} <: IO
    io::IO
    rule::Rule
end

create_rule(io::IO, rule::IORule) = IOWithRule(io, rule)

(rule::IORule)(io::IO) = create_rule(io, rule)

apply_rule(::IORule, data) = data

write_rule(io::IOWithRule, data) = write(io.io, apply_rule(io.rule, data))

Base.write(io::IOWithRule, data) = write_rule(io, data)
Base.write(io::IOWithRule, data::Vector{UInt8}) = write_rule(io, data)
Base.write(io::IOWithRule, s::Union{SubString{String}, String}) = write_rule(io, s)

close_rule(::IO) = nothing
close_rule(io::IOWithRule) = close_rule(io.io)

Base.close(io::IOWithRule) = close_rule(io)


struct Formatter <: IORule
    func::Function
end

apply_rule(rule::Formatter, data) = rule.func(data)

struct Color <: IORule
    Color(color::Symbol) = Formatter(x -> Base.text_colors[color] * x)
end


struct Split <: IORule
    split_func::Function
end

function write_rule(io::IOWithRule{Split}, data)
    for subdata in io.rule.split_func(data)
        write(io.io, subdata)
    end
end

split_line(s::AbstractString, n::Integer) = @views [s[i:min(i+n-1, end)] for i in 1:n:length(s)]

function add_newlines(strings::Vector{<:AbstractString})
    n = length(strings)
    return [i < n ? string(s, "\n") : s for (i, s) in enumerate(strings)]
end

struct LineSplit <: IORule
    LineSplit(width::Integer=displaysize(stdout)[2] - 5) =
        Split(line -> add_newlines(split_line(line, width)))
end


function format_block_line(
    prefix::AbstractString, content::AbstractString,
    prefix_color::Symbol=:blue, content_color::Symbol=:default,
)
    Base.text_colors[prefix_color] * "$prefix" * Base.text_colors[content_color] * content
end

struct Block <: IORule
    header::String
    color::Symbol
end

function create_rule(io::IO, rule::Block)
    print(io, format_block_line("╭─$(rule.header)", "\n", rule.color))
    return IOWithRule(io, rule)
end

function write_rule(io::IOWithRule{Block}, str::Union{SubString{String}, String})
    print(io.io, format_block_line("│ ", "", io.rule.color))
    write(io.io, str)
end

function close_rule(io::IOWithRule{Block})
    print(io.io, format_block_line("╰───┈─┈─┈┈┈ ┈ ┈", "\n", io.rule.color))
end


struct Lines <: IORule
    buffer::Vector{UInt8}
end

Lines() = Lines(UInt8[])

function write_rule(io::IOWithRule{Lines}, str::Union{SubString{String}, String})
    push!(io.rule.buffer, codeunits(str)...)
    while true
        last_newline_index = findfirst(x -> x == 0x0a, io.rule.buffer)
        if last_newline_index === nothing
            break
        end
        to_flush = io.rule.buffer[1:last_newline_index]
        write(io.io, String(to_flush))
        deleteat!(io.rule.buffer, 1:last_newline_index)
    end
    return nothing
end

function close_rule(io::IOWithRule{Lines})
    write_rule(io, "\n")
    close_rule(io.io)
end
