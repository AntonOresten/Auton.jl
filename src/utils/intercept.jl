function tee_stdout(f::Function, io::IO)
    old_stdout = stdout
    rd, wr = redirect_stdout()

    relay_task = @async begin
        try
            while true
                chunk = readavailable(rd)
                if !isempty(chunk)
                    write(io, chunk)
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
