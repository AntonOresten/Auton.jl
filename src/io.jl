function tee_stdout(f::Function, out::IO=IOBuffer())
    old_stdout = stdout
    rd, wr = redirect_stdout()
    relay_task = @async begin
        try
            while true
                chunk = readavailable(rd)
                if !isempty(chunk)
                    write(out, chunk)
                    write(IOContext(old_stdout, :color=>true), chunk)
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
    return out
end

function show_truncated_backtrace(io::IO; target=nothing)
    bt = catch_backtrace()
    frames = stacktrace(bt)
    idx = isnothing(target) ? nothing : findfirst(fr -> occursin(target, repr(fr)), frames)
    if idx !== nothing
        frames = frames[1:idx]
    end
    new_bt = Base.StackTraces.StackTrace(frames)
    Base.show_backtrace(io, new_bt)
end

print_error_header(io::IO) = print(io, Base.text_colors[:light_red], Base.text_colors[:bold], "ERROR: ", Base.text_colors[:normal])

function tee_stdout_with_stderr(f::Function; out::IO=IOBuffer(), err::IO=IOBuffer(), target=nothing)
    tee_stdout(out) do
        try
            f()
        catch e
            ctx = IOContext(err, :color=>true)
            print_error_header(ctx)
            showerror(ctx, e)
            show_truncated_backtrace(ctx; target)
        end
    end
    return out, err
end

# Base.display does not use stdout
function showdisplay(io::IO, x)
    show(IOContext(io, :limit=>true), MIME("text/plain"), x)
    println()
end

showdisplay(x) = showdisplay(stdout, x)
