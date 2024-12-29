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


struct Formatter{T<:IO,F<:Function} <: IO
    parent::T
    formatter::F
end

Formatter(f::Function, parent::IO) = Formatter(parent, f)

function Base.write(io::Formatter, data::Union{SubString{String}, String})
    write(io.parent, io.formatter(data))
end


struct Lines{T<:IO} <: IO
    parent::T
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

Base.println(io::Lines) = write(io, "\n")
